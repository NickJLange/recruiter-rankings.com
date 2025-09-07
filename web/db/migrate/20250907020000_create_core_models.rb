class CreateCoreModels < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :role, null: false, default: "candidate"
      t.string :email_hmac, null: false
      t.text :email_ciphertext
      t.string :email_kek_id
      t.string :linked_in_url
      t.timestamps
    end
    add_index :users, :email_hmac, unique: true
    add_index :users, :role

    create_table :companies do |t|
      t.string :name, null: false
      t.string :size_bucket
      t.string :website_url
      t.string :region
      t.timestamps
    end
    add_index :companies, :region

    create_table :recruiters do |t|
      t.string :name, null: false
      t.references :company, foreign_key: true
      t.string :region
      t.string :email_hmac
      t.text :email_ciphertext
      t.string :email_kek_id
      t.string :public_slug, null: false
      t.datetime :verified_at
      t.timestamps
    end
    add_index :recruiters, :email_hmac, unique: true
    add_index :recruiters, :public_slug, unique: true
    add_index :recruiters, :region

    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recruiter, foreign_key: true
      t.references :company, foreign_key: true
      t.integer :overall_score, null: false
      t.text :text
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :reviews, :status
    add_index :reviews, :recruiter_id
    add_index :reviews, :company_id

    create_table :review_metrics do |t|
      t.references :review, null: false, foreign_key: true
      t.string :dimension, null: false
      t.integer :score, null: false
      t.timestamps
    end
    add_index :review_metrics, [:review_id, :dimension], unique: true
    add_index :review_metrics, :dimension

    create_table :identity_challenges do |t|
      t.string :subject_type, null: false
      t.bigint :subject_id, null: false
      t.string :token_hash, null: false
      t.string :token
      t.datetime :expires_at, null: false
      t.datetime :verified_at
      t.timestamps
    end
    add_index :identity_challenges, [:subject_type, :subject_id]
    add_index :identity_challenges, :token_hash, unique: true
    add_index :identity_challenges, :expires_at

    create_table :takedown_requests do |t|
      t.string :subject_type, null: false
      t.bigint :subject_id, null: false
      t.string :reason_code
      t.string :requested_by
      t.string :status, null: false, default: "pending"
      t.datetime :sla_due_at
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :takedown_requests, [:subject_type, :subject_id]
    add_index :takedown_requests, :status
    add_index :takedown_requests, :sla_due_at

    create_table :moderation_actions do |t|
      t.references :actor, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :subject_type, null: false
      t.bigint :subject_id, null: false
      t.text :notes
      t.timestamps
    end
    add_index :moderation_actions, [:subject_type, :subject_id]
    add_index :moderation_actions, :actor_id

    create_table :profile_claims do |t|
      t.references :recruiter, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :verification_method, null: false
      t.datetime :verified_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :profile_claims, [:recruiter_id, :user_id], unique: true

    # Check constraints
    execute <<~SQL
      ALTER TABLE reviews
      ADD CONSTRAINT check_reviews_overall_score_range
      CHECK (overall_score >= 1 AND overall_score <= 5);
    SQL

    execute <<~SQL
      ALTER TABLE reviews
      ADD CONSTRAINT check_reviews_status
      CHECK (status IN ('pending','approved','removed','flagged'));
    SQL

    execute <<~SQL
      ALTER TABLE review_metrics
      ADD CONSTRAINT check_review_metrics_score_range
      CHECK (score >= 1 AND score <= 5);
    SQL

    execute <<~SQL
      ALTER TABLE takedown_requests
      ADD CONSTRAINT check_takedown_requests_status
      CHECK (status IN ('pending','in_review','resolved','rejected'));
    SQL

    execute <<~SQL
      ALTER TABLE users
      ADD CONSTRAINT check_users_role
      CHECK (role IN ('candidate','recruiter','moderator','admin'));
    SQL

    execute <<~SQL
      ALTER TABLE profile_claims
      ADD CONSTRAINT check_profile_claims_verification_method
      CHECK (verification_method IN ('li','email'));
    SQL
  end
end

