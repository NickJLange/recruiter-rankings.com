# Development seed data for Recruiter Rankings (synthetic-only)
# Safe to run multiple times; uses find_or_create_by!/upserts on unique keys.

# Safety guard for production
if Rails.env.production? && ENV["FORCE_SEED"] != "true"
  puts "Skipping seeds in production. Set FORCE_SEED=true to override."
  exit
end

require "securerandom"
require "openssl"

begin
  require "faker"
rescue LoadError
  puts "Faker gem not found. Skipping synthetic data generation."
  exit
end

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
    # Skewed distribution: mostly 3-5, occasional 1-2
    (rand * 10 > 2) ? rand(3..5) : rand(1..2)
  end
end

include SeedHelpers

puts "Seeding synthetic data with Faker..."

# 1. Companies
# Create a mix of small, medium, large companies
companies = []
20.times do
  name = Faker::Company.unique.name
  size = ["Small company", "Medium company", "Large company", "Enterprise"].sample
  region = ["US", "EU", "APAC", "Remote"].sample
  
  companies << Company.where(name: name).first_or_create!(
    size_bucket: size,
    website_url: Faker::Internet.url,
    region: region
  )
end

# 2. Recruiters
# Create 50 recruiters distributed across companies
recruiters = []
50.times do
  name = Faker::Name.unique.name
  slug = slugify(name)
  company = companies.sample
  
  recruiters << Recruiter.where(public_slug: slug).first_or_create!(
    name: name,
    company: company,
    region: company.region,
    verified_at: (rand > 0.7 ? Time.now : nil), # 30% verified
    email_hmac: (rand > 0.5 ? hmac_email("#{slug}@example.com") : nil)
  )
end

# 3. Users (Candidates & Staff)
users = []
# Fixed demo users
fixed_users = [
  { email: "alice@example.com", role: "candidate" },
  { email: "bob@example.com", role: "candidate" },
  { email: "mod@example.com", role: "moderator" },
  { email: "admin@example.com", role: "admin" }
]

fixed_users.each do |u|
  users << User.where(email_hmac: hmac_email(u[:email])).first_or_create!(
    role: u[:role],
    email_kek_id: "dev",
    linked_in_url: "https://linkedin.com/in/#{u[:email].split('@').first}"
  )
end

# Random candidates
30.times do
  email = Faker::Internet.unique.email
  users << User.where(email_hmac: hmac_email(email)).first_or_create!(
    role: "candidate",
    email_kek_id: "dev",
    linked_in_url: (rand > 0.2 ? Faker::Internet.url(host: "linkedin.com") : nil)
  )
end

# 4. Reviews
# Generate ~200 reviews
review_statuses = ["approved"] * 8 + ["pending"] * 1 + ["flagged"] * 1 # Mostly approved

200.times do
  recruiter = recruiters.sample
  user = users.select { |u| u.role == "candidate" }.sample
  
  # Skip if this user already reviewed this recruiter (simple uniqueness check)
  next if Review.exists?(user: user, recruiter: recruiter)

  overall = (rand * 10 > 1) ? rand(3..5) : rand(1..2) # Mostly positive
  status = review_statuses.sample
  
  # Varied text length
  text = if rand > 0.8
           Faker::Lorem.paragraphs(number: 3).join("\n\n") # Long review
         elsif rand > 0.3
           Faker::Lorem.paragraph # Medium review
         else
           Faker::Lorem.sentence # Short review
         end

  review = Review.create!(
    user: user,
    recruiter: recruiter,
    company: recruiter.company,
    overall_score: overall,
    text: text,
    status: status,
    created_at: Faker::Time.backward(days: 365)
  )

  # Metrics
  # Randomly skip some dimensions to test partial data
  DIMENSIONS.each do |dim|
    next if rand > 0.9 # 10% chance to miss a metric
    ReviewMetric.create!(
      review: review,
      dimension: dim,
      score: metric_value
    )
  end
end

puts "Seed complete: #{Company.count} companies, #{Recruiter.count} recruiters, #{User.count} users, #{Review.count} reviews."
