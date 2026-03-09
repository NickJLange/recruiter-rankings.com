# DEPRECATED: Review is the legacy data model from the admin moderation pipeline.
# New public submissions use Interaction + Experience (see those models).
# Admin controllers (Admin::ReviewsController) still read/write Review records.
# Future: migrate admin to read from Experience, migrate historical data, drop Review table.
class Review < ApplicationRecord
  belongs_to :user
  belongs_to :recruiter, optional: true
  belongs_to :company, optional: true
  has_many :review_metrics, dependent: :destroy
  has_many :review_responses, dependent: :destroy
  has_many :visible_review_responses, -> { visible }, class_name: "ReviewResponse"

  enum :status, {
    pending: "pending",
    approved: "approved",
    removed: "removed",
    flagged: "flagged"
  }

  validates :overall_score, inclusion: { in: 1..5 }
  validates :status, inclusion: { in: statuses.keys }
  validates :text, length: { maximum: 5000 }
end

