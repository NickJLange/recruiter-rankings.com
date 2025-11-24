class IdentityChallenge < ApplicationRecord
  belongs_to :subject, polymorphic: true

  validates :token_hash, presence: true
  validates :expires_at, presence: true
end

