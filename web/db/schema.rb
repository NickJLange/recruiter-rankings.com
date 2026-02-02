# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_19_170411) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "industry"
    t.string "name", null: false
    t.string "region"
    t.string "sector"
    t.string "size_bucket"
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["region"], name: "index_companies_on_region"
  end

  create_table "experiences", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "interaction_id", null: false
    t.integer "rating", null: false
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.boolean "would_recommend"
    t.index ["interaction_id"], name: "index_experiences_on_interaction_id"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "check_experiences_rating_range"
  end

  create_table "identity_challenges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.string "token"
    t.string "token_hash", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["expires_at"], name: "index_identity_challenges_on_expires_at"
    t.index ["subject_type", "subject_id"], name: "index_identity_challenges_on_subject_type_and_subject_id"
    t.index ["token_hash"], name: "index_identity_challenges_on_token_hash", unique: true
  end

  create_table "interactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "occurred_at"
    t.bigint "recruiter_id", null: false
    t.bigint "role_id"
    t.string "status", default: "pending"
    t.bigint "target_id", null: false
    t.datetime "updated_at", null: false
    t.index ["recruiter_id"], name: "index_interactions_on_recruiter_id"
    t.index ["role_id"], name: "index_interactions_on_role_id"
    t.index ["target_id"], name: "index_interactions_on_target_id"
  end

  create_table "moderation_actions", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_moderation_actions_on_actor_id"
    t.index ["subject_type", "subject_id"], name: "index_moderation_actions_on_subject_type_and_subject_id"
  end

  create_table "pay_charges", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "amount_refunded"
    t.integer "application_fee_amount"
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "customer_id", null: false
    t.jsonb "data"
    t.jsonb "metadata"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.bigint "subscription_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.boolean "default"
    t.datetime "deleted_at", precision: nil
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "deleted_at"], name: "pay_customer_owner_index", unique: true
    t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id", unique: true
  end

  create_table "pay_merchants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.boolean "default"
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "processor"], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"
  end

  create_table "pay_payment_methods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.jsonb "data"
    t.boolean "default"
    t.string "payment_method_type"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true
  end

  create_table "pay_subscriptions", force: :cascade do |t|
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "current_period_end", precision: nil
    t.datetime "current_period_start", precision: nil
    t.bigint "customer_id", null: false
    t.jsonb "data"
    t.datetime "ends_at", precision: nil
    t.jsonb "metadata"
    t.boolean "metered"
    t.string "name", null: false
    t.string "pause_behavior"
    t.datetime "pause_resumes_at", precision: nil
    t.datetime "pause_starts_at", precision: nil
    t.string "payment_method_id"
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.string "stripe_account"
    t.datetime "trial_ends_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index ["metered"], name: "index_pay_subscriptions_on_metered"
    t.index ["pause_starts_at"], name: "index_pay_subscriptions_on_pause_starts_at"
  end

  create_table "pay_webhooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "event"
    t.string "event_type"
    t.string "processor"
    t.datetime "updated_at", null: false
  end

  create_table "profile_claims", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "recruiter_id", null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "verification_method", null: false
    t.datetime "verified_at"
    t.index ["recruiter_id", "user_id"], name: "index_profile_claims_on_recruiter_id_and_user_id", unique: true
    t.index ["recruiter_id"], name: "index_profile_claims_on_recruiter_id"
    t.index ["user_id"], name: "index_profile_claims_on_user_id"
    t.check_constraint "verification_method::text = ANY (ARRAY['li'::character varying::text, 'email'::character varying::text])", name: "check_profile_claims_verification_method"
  end

  create_table "recruiters", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.text "email_ciphertext"
    t.string "email_hmac"
    t.string "email_kek_id"
    t.string "linkedin_url"
    t.string "name", null: false
    t.string "public_slug", null: false
    t.string "region"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["company_id"], name: "index_recruiters_on_company_id"
    t.index ["email_hmac"], name: "index_recruiters_on_email_hmac", unique: true
    t.index ["linkedin_url"], name: "index_recruiters_on_linkedin_url"
    t.index ["public_slug"], name: "index_recruiters_on_public_slug", unique: true
    t.index ["region"], name: "index_recruiters_on_region"
  end

  create_table "review_metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dimension", null: false
    t.bigint "experience_id", null: false
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.index ["dimension"], name: "index_review_metrics_on_dimension"
    t.index ["experience_id"], name: "index_review_metrics_on_experience_id"
    t.check_constraint "score >= 1 AND score <= 5", name: "check_review_metrics_score_range"
  end

  create_table "review_responses", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "review_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.boolean "visible", default: true, null: false
    t.index ["review_id"], name: "index_review_responses_on_review_id"
    t.index ["user_id"], name: "index_review_responses_on_user_id"
    t.index ["visible"], name: "index_review_responses_on_visible"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.integer "overall_score", null: false
    t.bigint "recruiter_id"
    t.string "status", default: "pending", null: false
    t.text "text"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["company_id"], name: "index_reviews_on_company_id"
    t.index ["recruiter_id"], name: "index_reviews_on_recruiter_id"
    t.index ["status"], name: "index_reviews_on_status"
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.check_constraint "overall_score >= 1 AND overall_score <= 5", name: "check_reviews_overall_score_range"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'approved'::character varying::text, 'removed'::character varying::text, 'flagged'::character varying::text])", name: "check_reviews_status"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "max_compensation"
    t.integer "min_compensation"
    t.date "posted_date"
    t.text "recruiter_take"
    t.bigint "recruiting_company_id", null: false
    t.bigint "target_company_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["recruiting_company_id"], name: "index_roles_on_recruiting_company_id"
    t.index ["target_company_id"], name: "index_roles_on_target_company_id"
  end

  create_table "takedown_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "reason_code"
    t.string "requested_by"
    t.datetime "resolved_at"
    t.datetime "sla_due_at"
    t.string "status", default: "pending", null: false
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.index ["sla_due_at"], name: "index_takedown_requests_on_sla_due_at"
    t.index ["status"], name: "index_takedown_requests_on_status"
    t.index ["subject_type", "subject_id"], name: "index_takedown_requests_on_subject_type_and_subject_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'in_review'::character varying::text, 'resolved'::character varying::text, 'rejected'::character varying::text])", name: "check_takedown_requests_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "email_ciphertext"
    t.string "email_hmac", null: false
    t.string "email_kek_id"
    t.string "linked_in_url"
    t.boolean "paid", default: false, null: false
    t.string "public_slug"
    t.string "role", default: "candidate", null: false
    t.datetime "updated_at", null: false
    t.string "verification_status"
    t.datetime "verified_at"
    t.index ["email_hmac"], name: "index_users_on_email_hmac", unique: true
    t.index ["public_slug"], name: "index_users_on_public_slug"
    t.index ["role"], name: "index_users_on_role"
    t.index ["verification_status"], name: "index_users_on_verification_status"
    t.check_constraint "role::text = ANY (ARRAY['candidate'::character varying::text, 'recruiter'::character varying::text, 'moderator'::character varying::text, 'admin'::character varying::text])", name: "check_users_role"
  end

  add_foreign_key "experiences", "interactions"
  add_foreign_key "interactions", "recruiters"
  add_foreign_key "interactions", "roles"
  add_foreign_key "interactions", "users", column: "target_id"
  add_foreign_key "moderation_actions", "users", column: "actor_id"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "profile_claims", "recruiters"
  add_foreign_key "profile_claims", "users"
  add_foreign_key "recruiters", "companies"
  add_foreign_key "review_metrics", "experiences"
  add_foreign_key "review_responses", "reviews"
  add_foreign_key "review_responses", "users"
  add_foreign_key "reviews", "companies"
  add_foreign_key "reviews", "recruiters"
  add_foreign_key "reviews", "users"
  add_foreign_key "roles", "companies", column: "recruiting_company_id"
  add_foreign_key "roles", "companies", column: "target_company_id"
end
