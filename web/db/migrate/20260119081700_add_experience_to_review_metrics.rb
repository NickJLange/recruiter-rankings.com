class AddExperienceToReviewMetrics < ActiveRecord::Migration[8.1]
  def change
    add_reference :review_metrics, :experience, null: false, foreign_key: true
    remove_reference :review_metrics, :review, foreign_key: true
  end
end
