class ReviewsController < ApplicationController
  protect_from_forgery with: :exception
  before_action -> { require_policy!(:candidate_submit) }, only: [:new, :create]

  def index
    recruiter = Recruiter.find_by!(public_slug: params[:recruiter_slug] || params[:recruiter_id])
    per = (params[:per].presence || 10).to_i
    reviews = recruiter.reviews.where(status: "approved").order(created_at: :desc).limit(per)
    render json: reviews.map { |r|
      { id: r.id, overall_score: r.overall_score, text: r.text, created_at: r.created_at.iso8601 }
    }
  end

  def new_global
    # Renders contextually — auth state checked in the view via auth_service helper
  end

  def new
    @recruiter = Recruiter.find_by!(public_slug: params[:recruiter_slug] || params[:recruiter_id])
  end

  def create
    recruiter = Recruiter.find_by!(public_slug: review_params[:recruiter_slug])
    status = demo_auto_approve? ? "approved" : "pending"
    rating = review_params[:overall_score].to_i

    unless (1..5).cover?(rating)
      @recruiter = recruiter
      flash.now[:alert] = "Please correct the errors below."
      return render :new, status: :unprocessable_entity
    end

    user = find_or_create_clerk_user

    Interaction.transaction do
      role = build_role(recruiter, review_params)

      occurred_at = parse_occurred_at(review_params[:occurred_at])

      interaction = Interaction.create!(
        recruiter: recruiter,
        target: user,
        occurred_at: occurred_at,
        status: status,
        clerk_user_id: auth_service.user_id,
        role: role
      )
      experience = interaction.create_experience!(
        rating: rating,
        body: review_params[:text],
        status: status,
        would_recommend: review_params[:would_recommend] == "1",
        outcome: review_params[:outcome].presence
      )

      dimension_scores = extract_dimension_scores(review_params)
      if dimension_scores.any?
        dimension_scores.each do |dim, score|
          experience.review_metrics.create!(dimension: dim, score: score)
        end
      elsif copy_overall_to_dimensions?
        ReviewMetric::DIMENSIONS.keys.each do |dim|
          experience.review_metrics.create!(dimension: dim, score: experience.rating)
        end
      end
    end

    redirect_to recruiter_path(recruiter.public_slug), notice: "Thanks! Your review has been submitted."
  rescue ActiveRecord::RecordInvalid
    @recruiter = recruiter
    flash.now[:alert] = "Please correct the errors below."
    render :new, status: :unprocessable_entity
  end

  private

  def review_params
    params.require(:review).permit(
      :recruiter_slug, :overall_score, :text,
      :occurred_at, :would_recommend, :outcome,
      :role_title, :role_min_compensation, :role_max_compensation, :role_target_company,
      *ReviewMetric::DIMENSIONS.keys.map { |d| :"dimension_#{d}" }
    )
  end

  def find_or_create_clerk_user
    cuid = auth_service.user_id
    User.where(clerk_user_id: cuid).first_or_create! do |u|
      u.email_hmac = OpenSSL::HMAC.hexdigest("SHA256", submission_email_hmac_pepper, "clerk:#{cuid}")
      u.role = "candidate"
    end
  end

  # Builds a Role if role_title is given and recruiter has a company.
  # Returns nil otherwise.
  def build_role(recruiter, params)
    return nil unless params[:role_title].present? && recruiter.company.present?

    target_company = Company.find_or_create_by!(name: params[:role_target_company].strip) \
      if params[:role_target_company].present?

    Role.create!(
      recruiting_company: recruiter.company,
      target_company: target_company,
      title: params[:role_title],
      min_compensation: params[:role_min_compensation].presence&.to_i,
      max_compensation: params[:role_max_compensation].presence&.to_i
    )
  end

  def parse_occurred_at(value)
    return Time.current if value.blank?
    Date.parse(value).to_time
  rescue ArgumentError, TypeError
    Time.current
  end

  # Returns a hash of { dimension_key => score } for submitted, in-range dimension scores.
  def extract_dimension_scores(params)
    ReviewMetric::DIMENSIONS.keys.each_with_object({}) do |dim, scores|
      raw = params[:"dimension_#{dim}"]
      next if raw.blank?
      score = raw.to_i
      scores[dim] = score if (1..5).cover?(score)
    end
  end
end
