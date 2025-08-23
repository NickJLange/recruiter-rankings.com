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

ActiveRecord::Schema[8.0].define(version: 2025_09_07_043000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "size_bucket"
    t.string "website_url"
    t.string "region"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region"], name: "index_companies_on_region"
  end

  create_table "identity_challenges", force: :cascade do |t|
    t.string "subject_type", null: false
    t.bigint "subject_id", null: false
    t.string "token_hash", null: false
    t.string "token"
    t.datetime "expires_at", null: false
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_identity_challenges_on_expires_at"
    t.index ["subject_type", "subject_id"], name: "index_identity_challenges_on_subject_type_and_subject_id"
    t.index ["token_hash"], name: "index_identity_challenges_on_token_hash", unique: true
  end

  create_table "moderation_actions", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "subject_type", null: false
    t.bigint "subject_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_moderation_actions_on_actor_id"
    t.index ["subject_type", "subject_id"], name: "index_moderation_actions_on_subject_type_and_subject_id"
  end

  create_table "profile_claims", force: :cascade do |t|
    t.bigint "recruiter_id", null: false
    t.bigint "user_id", null: false
    t.string "verification_method", null: false
    t.datetime "verified_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recruiter_id", "user_id"], name: "index_profile_claims_on_recruiter_id_and_user_id", unique: true
    t.index ["recruiter_id"], name: "index_profile_claims_on_recruiter_id"
    t.index ["user_id"], name: "index_profile_claims_on_user_id"
    t.check_constraint "verification_method::text = ANY (ARRAY['li'::character varying, 'email'::character varying]::text[])", name: "check_profile_claims_verification_method"
  end

  create_table "recruiters", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "company_id"
    t.string "region"
    t.string "email_hmac"
    t.text "email_ciphertext"
    t.string "email_kek_id"
    t.string "public_slug", null: false
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_recruiters_on_company_id"
    t.index ["email_hmac"], name: "index_recruiters_on_email_hmac", unique: true
    t.index ["public_slug"], name: "index_recruiters_on_public_slug", unique: true
    t.index ["region"], name: "index_recruiters_on_region"
  end

  create_table "review_metrics", force: :cascade do |t|
    t.bigint "review_id", null: false
    t.string "dimension", null: false
    t.integer "score", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dimension"], name: "index_review_metrics_on_dimension"
    t.index ["review_id", "dimension"], name: "index_review_metrics_on_review_id_and_dimension", unique: true
    t.index ["review_id"], name: "index_review_metrics_on_review_id"
    t.check_constraint "score >= 1 AND score <= 5", name: "check_review_metrics_score_range"
  end

  create_table "review_responses", force: :cascade do |t|
    t.bigint "review_id", null: false
    t.bigint "user_id"
    t.text "body", null: false
    t.boolean "visible", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id"], name: "index_review_responses_on_review_id"
    t.index ["user_id"], name: "index_review_responses_on_user_id"
    t.index ["visible"], name: "index_review_responses_on_visible"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "recruiter_id"
    t.bigint "company_id"
    t.integer "overall_score", null: false
    t.text "text"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_reviews_on_company_id"
    t.index ["recruiter_id"], name: "index_reviews_on_recruiter_id"
    t.index ["status"], name: "index_reviews_on_status"
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.check_constraint "overall_score >= 1 AND overall_score <= 5", name: "check_reviews_overall_score_range"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'removed'::character varying, 'flagged'::character varying]::text[])", name: "check_reviews_status"
  end

  create_table "takedown_requests", force: :cascade do |t|
    t.string "subject_type", null: false
    t.bigint "subject_id", null: false
    t.string "reason_code"
    t.string "requested_by"
    t.string "status", default: "pending", null: false
    t.datetime "sla_due_at"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sla_due_at"], name: "index_takedown_requests_on_sla_due_at"
    t.index ["status"], name: "index_takedown_requests_on_status"
    t.index ["subject_type", "subject_id"], name: "index_takedown_requests_on_subject_type_and_subject_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'in_review'::character varying, 'resolved'::character varying, 'rejected'::character varying]::text[])", name: "check_takedown_requests_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "role", default: "candidate", null: false
    t.string "email_hmac", null: false
    t.text "email_ciphertext"
    t.string "email_kek_id"
    t.string "linked_in_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_hmac"], name: "index_users_on_email_hmac", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.check_constraint "role::text = ANY (ARRAY['candidate'::character varying, 'recruiter'::character varying, 'moderator'::character varying, 'admin'::character varying]::text[])", name: "check_users_role"
  end

  add_foreign_key "moderation_actions", "users", column: "actor_id"
  add_foreign_key "profile_claims", "recruiters"
  add_foreign_key "profile_claims", "users"
  add_foreign_key "recruiters", "companies"
  add_foreign_key "review_metrics", "reviews"
  add_foreign_key "review_responses", "reviews"
  add_foreign_key "review_responses", "users"
  add_foreign_key "reviews", "companies"
  add_foreign_key "reviews", "recruiters"
  add_foreign_key "reviews", "users"
end
