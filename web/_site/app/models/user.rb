class User < ApplicationRecord
  has_many :reviews, dependent: :nullify
  has_many :moderation_actions, foreign_key: :actor_id, dependent: :nullify
  has_many :profile_claims, dependent: :destroy

  enum :role, {
    candidate: "candidate",
    recruiter: "recruiter",
    moderator: "moderator",
    admin: "admin"
  }, prefix: true

  validates :email_hmac, presence: true, uniqueness: true
end

