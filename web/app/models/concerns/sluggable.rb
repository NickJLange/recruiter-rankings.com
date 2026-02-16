module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_masked_slug, on: :create
  end

  private

  def generate_masked_slug
    return if public_slug.present?
    loop do
      self.public_slug = SecureRandom.hex(4).upcase
      break unless self.class.exists?(public_slug: public_slug)
    end
  end
end
