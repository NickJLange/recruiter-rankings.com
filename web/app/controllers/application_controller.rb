class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :public_min_reviews, :demo_auto_approve?, :submission_email_hmac_pepper, :copy_overall_to_dimensions?

  private

  def public_min_reviews
    (ENV["PUBLIC_MIN_REVIEWS"].presence || (Rails.env.development? ? 1 : 5)).to_i
  end

  def demo_auto_approve?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_AUTO_APPROVE", Rails.env.development?.to_s))
  end

  def submission_email_hmac_pepper
    ENV.fetch("SUBMISSION_EMAIL_HMAC_PEPPER", "demo-only-pepper-not-secret")
  end

  def copy_overall_to_dimensions?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("SUBMISSION_COPY_OVERALL_TO_DIMENSIONS", "true"))
  end
end
