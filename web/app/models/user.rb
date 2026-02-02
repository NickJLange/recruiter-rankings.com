class User < ApplicationRecord
  pay_customer
  has_many :reviews, dependent: :nullify
  has_many :interactions, foreign_key: :target_id, dependent: :destroy
  has_many :moderation_actions, foreign_key: :actor_id, dependent: :nullify
  has_many :profile_claims, dependent: :destroy
  
  validates :public_slug, uniqueness: true, allow_nil: true
  before_validation :generate_masked_slug, on: :create

  enum :role, {
    candidate: "candidate",
    recruiter: "recruiter",
    moderator: "moderator",
    admin: "admin"
  }

  enum :verification_status, {
    unverified: "unverified",
    pending: "pending",
    verified: "verified",
    rejected: "rejected"
  }, prefix: :identity

  def paid?
    # Allow manual override via 'paid' column or check Pay subscriptions
    paid || (respond_to?(:payment_processor) && payment_processor&.subscribed?) || (respond_to?(:pay_customers) && pay_customers.any? { |c| c.subscribed? })
  end

  def admin?
    role == "admin"
  end

  def owner_of_review?(recruiter)
    # Check if user has an approved interaction (review) for this recruiter
    interactions.where(recruiter: recruiter, status: "approved").exists?
  end

  private

  def generate_masked_slug
    return if public_slug.present?
    loop do
      self.public_slug = SecureRandom.hex(4).upcase
      break unless User.exists?(public_slug: public_slug)
    end
  end
end

