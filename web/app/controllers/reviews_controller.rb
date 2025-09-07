class ReviewsController < ApplicationController
  protect_from_forgery with: :exception

  def new
    @recruiter = Recruiter.find_by!(public_slug: params[:recruiter_slug] || params[:recruiter_id])
    @review = Review.new(recruiter: @recruiter, company: @recruiter.company)
  end

  def create
    recruiter = Recruiter.find_by!(public_slug: review_params[:recruiter_slug])
    user = find_or_create_user(review_params[:email])

    status = demo_auto_approve? ? "approved" : "pending"

    review = Review.new(
      user: user,
      recruiter: recruiter,
      company: recruiter.company,
      overall_score: review_params[:overall_score],
      text: review_params[:text],
      status: status
    )

    if review.save
      if copy_overall_to_dimensions?
        ReviewMetric::DIMENSIONS.keys.each do |dim|
          review.review_metrics.create!(dimension: dim, score: review.overall_score)
        end
      end
      redirect_to recruiter_path(recruiter.public_slug), notice: "Thanks! Your review has been submitted."
    else
      @recruiter = recruiter
      @review = review
      flash.now[:alert] = "Please correct the errors below."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def review_params
    params.require(:review).permit(:recruiter_slug, :overall_score, :text, :email)
  end

  def hmac_email(email)
    pepper = Rails.configuration.x.submission_email_hmac_pepper
    pepper = pepper.is_a?(String) && pepper.present? ? pepper : "demo-only-pepper-not-secret"
    OpenSSL::HMAC.hexdigest("SHA256", pepper, email)
  end

  def find_or_create_user(email)
    email = email.to_s.strip
    email_to_hash = email.empty? ? "anon-#{SecureRandom.uuid}@example.com" : email
    hmac = hmac_email(email_to_hash)
    User.where(email_hmac: hmac).first_or_create! do |u|
      u.role = "candidate"
      u.email_kek_id = "demo"
      u.linked_in_url = nil
    end
  end

  def demo_auto_approve?
    ActiveModel::Type::Boolean.new.cast(Rails.configuration.x.demo_auto_approve)
  end

  def copy_overall_to_dimensions?
    ActiveModel::Type::Boolean.new.cast(Rails.configuration.x.copy_overall_to_dimensions)
  end
end

