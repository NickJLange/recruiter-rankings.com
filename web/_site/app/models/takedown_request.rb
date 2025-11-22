class TakedownRequest < ApplicationRecord
  belongs_to :subject, polymorphic: true

  enum :status, {
    pending: "pending",
    in_review: "in_review",
    resolved: "resolved",
    rejected: "rejected"
  }

  validates :status, inclusion: { in: statuses.keys }
end

