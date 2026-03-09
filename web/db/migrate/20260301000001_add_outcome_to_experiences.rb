class AddOutcomeToExperiences < ActiveRecord::Migration[8.1]
  def up
    add_column :experiences, :outcome, :string
    execute <<~SQL
      ALTER TABLE experiences ADD CONSTRAINT check_experiences_outcome
        CHECK (outcome IS NULL OR outcome IN ('hired','declined_offer','ghosted','still_interviewing'))
    SQL
  end

  def down
    execute "ALTER TABLE experiences DROP CONSTRAINT IF EXISTS check_experiences_outcome"
    remove_column :experiences, :outcome
  end
end
