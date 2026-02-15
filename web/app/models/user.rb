class User < ApplicationRecord
  has_many :reviews
  has_many :profile_claims
  has_many :review_responses
  has_many :identity_challenges, as: :subject, dependent: :destroy

  validates :email_hmac, presence: true, uniqueness: true
  validates :role, presence: true

  def self.generate_email_hmac(email)
    pepper = ENV["SUBMISSION_EMAIL_HMAC_PEPPER"]
    if pepper.blank?
      if Rails.env.production?
        raise "SUBMISSION_EMAIL_HMAC_PEPPER must be set in production"
      else
        pepper = "demo-only-pepper-not-secret"
      end
    end

    OpenSSL::HMAC.hexdigest("SHA256", pepper, email)
  end
end
