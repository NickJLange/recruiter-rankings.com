class EmailIdentityService
  def initialize(pepper: nil)
    @pepper = pepper || ENV.fetch("SUBMISSION_EMAIL_HMAC_PEPPER", "demo-only-pepper-not-secret")
  end

  def hmac_email(email)
    email = email.to_s.strip
    email = "anon-#{SecureRandom.uuid}@example.com" if email.empty?
    OpenSSL::HMAC.hexdigest("SHA256", @pepper, email)
  end

  def find_or_create_user(email)
    hmac = hmac_email(email)
    User.where(email_hmac: hmac).first_or_create! do |u|
      u.role = "candidate"
      u.email_kek_id = "demo"
      u.linked_in_url = nil
    end
  end
end
