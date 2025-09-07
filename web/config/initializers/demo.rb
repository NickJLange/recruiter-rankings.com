Rails.application.configure do
  # Public aggregate suppression threshold (only show recruiters with >= this many approved reviews)
  config.x.public_min_reviews = ENV.fetch("PUBLIC_MIN_REVIEWS", "5").to_i

  # Demo flow: auto-approve new reviews?
  config.x.demo_auto_approve = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_AUTO_APPROVE", "false"))

  # Pepper used to HMAC emails submitted via demo review form (not secret in demo)
  config.x.submission_email_hmac_pepper = ENV.fetch("SUBMISSION_EMAIL_HMAC_PEPPER", "demo-only-pepper-not-secret")

  # If true, when sub-dimension scores are not provided, copy overall_score into each dimension for demo purposes
  config.x.copy_overall_to_dimensions = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SUBMISSION_COPY_OVERALL_TO_DIMENSIONS", "true"))
end

