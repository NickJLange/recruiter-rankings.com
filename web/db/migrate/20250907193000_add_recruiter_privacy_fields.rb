class AddRecruiterPrivacyFields < ActiveRecord::Migration[8.0]
  def change
    add_column :recruiters, :linkedin_url, :string
    add_column :recruiters, :consented_at, :datetime
    add_index :recruiters, :linkedin_url
  end
end
