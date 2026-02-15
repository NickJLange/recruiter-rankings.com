class Recruiter < ApplicationRecord
  belongs_to :company, optional: true
  has_many :reviews, dependent: :nullify
  has_many :interactions, dependent: :destroy
  has_many :profile_claims, dependent: :destroy

  validates :name, presence: true
  validates :public_slug, presence: true, uniqueness: true
  validates :email_hmac, uniqueness: true, allow_nil: true
  before_validation :generate_masked_slug, on: :create
  
  # Override to use public_slug for routing
  def to_param
    public_slug
  end

  def display_name(viewer = nil)
    return name if viewer&.admin? || viewer&.paid? || viewer&.owner_of_review?(self)
    
    # Masked name
    # Masked name
    # If slug is hex, just show "Recruiter <SLUG>"
    if public_slug.match?(/\A[0-9A-F]{8}\z/)
      "Recruiter #{public_slug}"
    elsif public_slug.start_with?("RR-")
      "Recruiter #{public_slug.split('-').last}"
    else
      # Legacy or custom slug fallback
      "Recruiter #{Digest::MD5.hexdigest(public_slug)[0..5].upcase}"
    end
  end

  private

  def generate_masked_slug
    return if public_slug.present? && !public_slug.include?("-") # Keep existing if valid hex? No, we want to enforce it.
    # Actually, we should allow overwriting if it looks like a legacy slug? 
    # For callback, we just ensure it's set on create. The migration will handle updates.
    return if public_slug.present?
    
    loop do
      self.public_slug = SecureRandom.hex(4).upcase # 4 bytes = 8 hex chars
      break unless Recruiter.exists?(public_slug: public_slug)
    end
  end
end

