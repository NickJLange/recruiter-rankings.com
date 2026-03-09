module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_masked_slug, on: :create
  end

  private

  def generate_masked_slug
    return if public_slug.present?
    loop do
      candidate = SecureRandom.hex(4).upcase
      next if self.class.exists?(public_slug: candidate)
      self.public_slug = candidate
      break
    end
  end
end
