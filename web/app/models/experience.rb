class Experience < ApplicationRecord
  belongs_to :interaction
  has_many :review_metrics, dependent: :destroy

  OUTCOMES = %w[hired declined_offer ghosted still_interviewing].freeze

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :status, presence: true
  validates :outcome, inclusion: { in: OUTCOMES }, allow_nil: true

  scope :approved_aggregates_by_recruiter, -> {
    where(status: "approved")
      .joins(:interaction)
      .group("interactions.recruiter_id")
      .select("interactions.recruiter_id, COUNT(*) AS reviews_count, AVG(rating) AS avg_overall")
  }

  scope :approved_aggregates_by_company, -> {
    where(status: "approved")
      .joins(interaction: :recruiter)
      .group("recruiters.company_id")
      .select("recruiters.company_id AS company_id, COUNT(*) AS reviews_count, AVG(rating) AS avg_overall")
  }
end
