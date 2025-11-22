class CreateReviewResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :review_responses do |t|
      t.references :review, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.text :body, null: false
      t.boolean :visible, null: false, default: true
      t.timestamps
    end

    add_index :review_responses, :visible
  end
end

