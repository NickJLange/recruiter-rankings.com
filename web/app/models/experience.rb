class Experience < ApplicationRecord
  belongs_to :interaction
  has_many :review_metrics, dependent: :destroy

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :status, presence: true
end
