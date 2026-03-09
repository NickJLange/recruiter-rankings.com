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
  professionalism_respect
  job_match_quality
].freeze

job_titles = [
  "Software Engineer",
  "Senior Software Engineer",
  "Product Manager",
  "Engineering Manager",
  "Product Designer",
  "Data Scientist",
  "Solutions Architect"
]

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
    (rand * 10 > 2) ? rand(3..5) : rand(1..2)
  end

  def random_comp
    min = (rand(80..220) * 1000)
    max = min + (rand(10..50) * 1000)
    [min, max]
  end
end

include SeedHelpers

puts "Seeding synthetic data with Faker..."

# 1. Companies
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
recruiters = []
50.times do
  name = Faker::Name.unique.name
  slug = SecureRandom.hex(4).upcase
  company = companies.sample
  
  recruiters << Recruiter.where(public_slug: slug).first_or_create!(
    name: name,
    company: company,
    region: company.region,
    verified_at: (rand > 0.7 ? Time.now : nil),
    email_hmac: (rand > 0.5 ? hmac_email("#{slug}@example.com") : nil)
  )
end

# 3. Users
users = []
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

30.times do
  email = Faker::Internet.unique.email
  users << User.where(email_hmac: hmac_email(email)).first_or_create!(
    role: "candidate",
    email_kek_id: "dev",
    linked_in_url: (rand > 0.2 ? Faker::Internet.url(host: "linkedin.com") : nil)
  )
end

# 4. Interactions
puts "Generating interactions..."

recruiters.first(10).each do |recruiter|
  7.times do
    target = users.sample
    occurred = rand(1..24).months.ago
    target_company = (companies - [recruiter.company]).sample || companies.first
    
    c_min, c_max = random_comp
    role = Role.create!(
      title: job_titles.sample,
      recruiting_company: recruiter.company,
      target_company: target_company,
      min_compensation: c_min,
      max_compensation: c_max,
      posted_date: rand(1..60).days.ago,
      description: Faker::Lorem.paragraph
    )

    i = Interaction.create!(
      recruiter: recruiter,
      target: target,
      occurred_at: occurred,
      status: "approved",
      role: role
    )

    exp = Experience.create!(
      interaction: i,
      rating: rand(3..5),
      body: Faker::Lorem.paragraph(sentence_count: 3),
      status: "approved",
      would_recommend: true
    )

    ReviewMetric::DIMENSIONS.values.sample(3).each do |dim|
      ReviewMetric.create!(
        experience: exp,
        dimension: dim,
        score: rand(3..5)
      )
    end
  end
end

100.times do
  recruiter = recruiters.drop(10).sample
  user = users.sample
  next if Interaction.exists?(target: user, recruiter: recruiter)

  target_company = (companies - [recruiter.company]).sample || companies.first
  c_min, c_max = random_comp
  
  role = Role.create!(
    title: job_titles.sample,
    recruiting_company: recruiter.company,
    target_company: target_company,
    min_compensation: c_min,
    max_compensation: c_max,
    posted_date: rand(1..60).days.ago
  )

  status = (rand > 0.1) ? "approved" : "pending"
  i = Interaction.create!(
    recruiter: recruiter,
    target: user,
    occurred_at: rand(1..12).months.ago,
    status: status,
    role: role
  )

  exp = Experience.create!(
    interaction: i,
    rating: rand(1..5),
    body: Faker::Lorem.sentence,
    status: status,
    would_recommend: rand > 0.5
  )

  if status == "approved"
    ReviewMetric::DIMENSIONS.values.sample(2).each do |dim|
      ReviewMetric.create!(
        experience: exp,
        dimension: dim,
        score: rand(1..5)
      )
    end
  end
end

puts "Seed complete: #{Company.count} companies, #{Recruiter.count} recruiters, #{User.count} users, #{Interaction.count} interactions."
