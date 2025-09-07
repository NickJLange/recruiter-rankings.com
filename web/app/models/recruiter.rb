class Recruiter < ApplicationRecord
  belongs_to :company, optional: true
  has_many :reviews, dependent: :nullify
  has_many :profile_claims, dependent: :destroy

  validates :name, presence: true
  validates :public_slug, presence: true, uniqueness: true
  validates :email_hmac, uniqueness: true, allow_nil: true

  def consented?
    consented_at.present?
  end

  def pseudonym
    require 'digest'
    base = email_hmac.presence || public_slug.presence || id.to_s
    pepper = ENV['DISPLAY_HASH_PEPPER'].presence || 'demo-display-hash-pepper'
    "RR-#{Digest::SHA256.hexdigest("#{pepper}:#{base}")[0,10]}"
  end
end

