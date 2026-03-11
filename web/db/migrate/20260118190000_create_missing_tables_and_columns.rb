class CreateMissingTablesAndColumns < ActiveRecord::Migration[8.1]
  def change
    # roles — referenced by interactions.role_id and the change_role_compensation_to_numeric
    # migration that follows. Starts with compensation_range:string; that migration converts
    # it to separate min/max_compensation integer columns.
    create_table :roles do |t|
      t.references :recruiting_company, null: false, foreign_key: { to_table: :companies }
      t.references :target_company, foreign_key: { to_table: :companies }
      t.string :title
      t.text :description
      t.string :url
      t.date :posted_date
      t.text :recruiter_take
      t.string :compensation_range
      t.timestamps
    end

    # interactions — the core unit of a user's encounter with a recruiter/role.
    # clerk_user_id is added later by add_clerk_user_id_to_users_and_interactions.
    create_table :interactions do |t|
      t.references :recruiter, null: false, foreign_key: true
      t.references :role, foreign_key: true
      t.references :target, null: false, foreign_key: { to_table: :users }
      t.string :status, default: "pending"
      t.datetime :occurred_at
      t.timestamps
    end

    # experiences — a reviewer's written assessment of an interaction.
    # outcome column is added later by add_outcome_to_experiences.
    create_table :experiences do |t|
      t.references :interaction, null: false, foreign_key: true
      t.integer :rating, null: false
      t.boolean :would_recommend
      t.text :body
      t.string :status, default: "pending"
      t.timestamps
    end

    execute <<~SQL
      ALTER TABLE experiences ADD CONSTRAINT check_experiences_rating_range
        CHECK (rating >= 1 AND rating <= 5);
    SQL

    # Missing columns on companies (present in schema.rb but not in create_core_models)
    add_column :companies, :industry, :string
    add_column :companies, :sector, :string

    # Missing columns on users
    add_column :users, :paid, :boolean, default: false, null: false
    add_column :users, :verification_status, :string
    add_column :users, :verified_at, :datetime
    add_index :users, :verification_status

    # Missing column on recruiters (linkedin_url, distinct from users.linked_in_url)
    add_column :recruiters, :linkedin_url, :string
  end
end
