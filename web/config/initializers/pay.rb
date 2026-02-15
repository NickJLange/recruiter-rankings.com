Pay.setup do |config|
  # For Paddle Billing
  processors = [:paddle_billing]
  processors << :fake_processor if Rails.env.test? || Rails.env.development?
  config.enabled_processors = processors

  config.business_name = "Recruiter Rankings"
  config.support_email = "support@recruiter-rankings.com"
  config.application_name = "Recruiter Rankings"
  
  # Paddle Billing Configuration is handled via ENV variables:
  # PADDLE_BILLING_API_KEY
  # PADDLE_BILLING_CLIENT_TOKEN
  # PADDLE_BILLING_ENVIRONMENT (sandbox/production)
end
