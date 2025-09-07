# Demo configuration (ENV-driven with sane defaults)
Rails.configuration.x.public_min_reviews = ENV.fetch("PUBLIC_MIN_REVIEWS", "5").to_i
Rails.configuration.x.demo_auto_approve = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_AUTO_APPROVE", "false"))
Rails.configuration.x.submission_email_hmac_pepper = ENV.fetch("SUBMISSION_EMAIL_HMAC_PEPPER", "demo-only-pepper-not-secret")
Rails.configuration.x.copy_overall_to_dimensions = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SUBMISSION_COPY_OVERALL_TO_DIMENSIONS", "true"))

