class ReviewResponse < ApplicationRecord
  belongs_to :review
  belongs_to :user, optional: true

  validates :body, presence: true, length: { minimum: 2 }

  scope :visible, -> { where(visible: true) }
end

