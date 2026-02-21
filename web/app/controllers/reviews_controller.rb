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
      interaction = Interaction.create!(
        recruiter: recruiter,
        target: user,
        occurred_at: Time.current,
        status: status,
        clerk_user_id: auth_service.user_id
      )
      experience = interaction.create_experience!(
        rating: rating,
        body: review_params[:text],
        status: status
      )
      if copy_overall_to_dimensions?
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
    params.require(:review).permit(:recruiter_slug, :overall_score, :text)
  end

  def find_or_create_clerk_user
    cuid = auth_service.user_id
    User.where(clerk_user_id: cuid).first_or_create! do |u|
      u.email_hmac = OpenSSL::HMAC.hexdigest("SHA256", submission_email_hmac_pepper, "clerk:#{cuid}")
      u.role = "candidate"
    end
  end
end
