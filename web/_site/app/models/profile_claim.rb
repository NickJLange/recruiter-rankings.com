class ProfileClaim < ApplicationRecord
  belongs_to :recruiter
  belongs_to :user

  enum :verification_method, {
    li: "li",
    email: "email"
  }

  validates :verification_method, inclusion: { in: verification_methods.keys }
end

