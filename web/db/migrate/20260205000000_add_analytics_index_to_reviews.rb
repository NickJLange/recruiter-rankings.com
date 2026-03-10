class AddAnalyticsIndexToReviews < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :reviews, [:status, :recruiter_id, :overall_score], name: "index_reviews_on_status_recruiter_overall", algorithm: :concurrently, if_not_exists: true
  end
end
