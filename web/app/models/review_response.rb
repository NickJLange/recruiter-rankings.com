# DEPRECATED: ReviewResponse belongs to Review (the legacy model).
# When Review is migrated to Experience, responses will need an equivalent
# association on Experience. See Review model for full deprecation context.
class ReviewResponse < ApplicationRecord
  belongs_to :review
  belongs_to :user, optional: true

  validates :body, presence: true, length: { minimum: 2 }

  scope :visible, -> { where(visible: true) }
end

