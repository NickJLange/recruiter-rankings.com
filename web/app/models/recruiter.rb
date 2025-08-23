class Recruiter < ApplicationRecord
  belongs_to :company, optional: true
  has_many :reviews, dependent: :nullify
  has_many :profile_claims, dependent: :destroy

  validates :name, presence: true
  validates :public_slug, presence: true, uniqueness: true
  validates :email_hmac, uniqueness: true, allow_nil: true
end

