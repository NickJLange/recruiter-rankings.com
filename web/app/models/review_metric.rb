# NOTE: ReviewMetric belongs_to :experience (not Review). Despite the name, this model
# stores dimensional scores for the Experience model. The "review_" prefix is a naming
# artifact from before the Interaction/Experience refactor. See Review model for deprecation context.
class ReviewMetric < ApplicationRecord
  belongs_to :experience

  DIMENSIONS = {
    responsiveness: "responsiveness",
    role_clarity: "role_clarity",
    candidate_understanding: "candidate_understanding",
    fairness_inclusivity: "fairness_inclusivity",
    timeline_management: "timeline_management",
    feedback_quality: "feedback_quality",
    professionalism_respect: "professionalism_respect",
    job_match_quality: "job_match_quality"
  }.freeze

  enum :dimension, DIMENSIONS

  validates :score, inclusion: { in: 1..5 }
  validates :dimension, inclusion: { in: DIMENSIONS.keys.map(&:to_s) }
end

