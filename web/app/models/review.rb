class Review < ApplicationRecord
  belongs_to :user
  belongs_to :recruiter, optional: true
  belongs_to :company, optional: true
  has_many :review_metrics, dependent: :destroy
  has_many :review_responses, dependent: :destroy

  enum :status, {
    pending: "pending",
    approved: "approved",
    removed: "removed",
    flagged: "flagged"
  }

  validates :overall_score, inclusion: { in: 1..5 }
  validates :status, inclusion: { in: statuses.keys }
end

