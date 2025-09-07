# Development seed data for Recruiter Rankings (synthetic-only)
# Safe to run multiple times; uses find_or_create_by!/upserts on unique keys.

require "securerandom"
require "openssl"

PEPPER = ENV.fetch("DEV_EMAIL_HMAC_PEPPER", "dev-only-pepper-not-secret")

DIMENSIONS = %w[
  responsiveness
  role_clarity
  candidate_understanding
  fairness_inclusivity
  timeline_management
  feedback_quality
  professionalism_respect
  job_match_quality
].freeze

# Helpers
module SeedHelpers
  module_function

  def hmac_email(email)
    OpenSSL::HMAC.hexdigest("SHA256", PEPPER, email)
  end

  def slugify(name)
    name.parameterize
  end

  def metric_value
    # Bias toward 3-5 for a friendlier demo
    [2,3,3,4,4,5,5].sample
  end
end

include SeedHelpers

puts "Seeding synthetic data..."

# Companies
companies_data = [
  { name: "Acme Talent Group", size_bucket: "Small company", website_url: "https://acme.example", region: "US" },
  { name: "Globex Recruiting", size_bucket: "Medium company", website_url: "https://globex.example", region: "US" },
  { name: "Initech Staffing", size_bucket: "Small company", website_url: "https://initech.example", region: "US" },
  { name: "Stark Industries HR", size_bucket: "Large company", website_url: "https://stark.example", region: "US" }
]

companies = companies_data.map do |attrs|
  Company.where(name: attrs[:name]).first_or_create!(attrs)
end

# Recruiters
recruiters_data = [
  { name: "Ava Tanaka", company: companies[0], region: "US" },
  { name: "Liam O'Connell", company: companies[1], region: "US" },
  { name: "Sora Watanabe", company: companies[2], region: "US" },
  { name: "Maya Kapoor", company: companies[3], region: "US" },
  { name: "Diego Fernández", company: companies[1], region: "US" }
]

recruiters = recruiters_data.map do |attrs|
  slug = slugify(attrs[:name])
  Recruiter.where(public_slug: slug).first_or_create! do |r|
    r.name = attrs[:name]
    r.company = attrs[:company]
    r.region = attrs[:region]
    r.public_slug = slug
    r.verified_at = [true, false].sample ? Time.now : nil
    r.email_hmac = [true, false].sample ? hmac_email("#{slug}@example.com") : nil
  end
end

# Users (candidates)
users_data = [
  { email: "alice@example.com", role: "candidate", linked_in_url: "https://www.linkedin.com/in/alice-demo" },
  { email: "bob@example.com", role: "candidate", linked_in_url: "https://www.linkedin.com/in/bob-demo" },
  { email: "carol@example.com", role: "candidate", linked_in_url: "https://www.linkedin.com/in/carol-demo" },
  { email: "dave@example.com", role: "candidate", linked_in_url: "https://www.linkedin.com/in/dave-demo" },
  { email: "erin@example.com", role: "candidate", linked_in_url: "https://www.linkedin.com/in/erin-demo" },
  { email: "mod@example.com", role: "moderator", linked_in_url: nil },
  { email: "admin@example.com", role: "admin", linked_in_url: nil }
]

users = users_data.map do |u|
  User.where(email_hmac: hmac_email(u[:email])).first_or_create! do |user|
    user.role = u[:role]
    user.email_ciphertext = nil # dev only
    user.email_kek_id = "dev"
    user.linked_in_url = u[:linked_in_url]
  end
end

# Reviews + metrics
review_texts = [
  "Clear communication and timely follow‑ups.",
  "Role description was a bit generic, but the process was respectful.",
  "Great understanding of my constraints; quick feedback loops.",
  "Slow response time; unclear timeline.",
  "Very professional; matched me to a relevant role."
]

users.take(5).each_with_index do |user, idx|
  recruiter = recruiters[idx % recruiters.length]
  company = recruiter.company
  overall = [3,4,4,5,2].sample
  status = %w[pending approved approved approved flagged].sample

  review = Review.where(user: user, recruiter: recruiter, company: company, text: review_texts[idx % review_texts.length]).first_or_create! do |r|
    r.overall_score = overall
    r.status = status
  end

  # Metrics per review (one per dimension)
  DIMENSIONS.each do |dim|
    ReviewMetric.where(review: review, dimension: dim).first_or_create! do |m|
      m.score = metric_value
    end
  end
end

# Example profile claim (unverified)
if recruiters.first && users.first
  ProfileClaim.where(recruiter: recruiters.first, user: users.first).first_or_create! do |pc|
    pc.verification_method = "li"
    pc.verified_at = nil
  end
end

# Example moderation action
moderator = users.find { |u| u.role == "moderator" }
if moderator && Review.first
  ModerationAction.where(actor: moderator, subject: Review.first, action: "flag_for_review").first_or_create! do |ma|
    ma.notes = "Auto-flagged due to PII scrubber match."
  end
end

puts "Seed complete: #{Company.count} companies, #{Recruiter.count} recruiters, #{User.count} users, #{Review.count} reviews, #{ReviewMetric.count} metrics."
