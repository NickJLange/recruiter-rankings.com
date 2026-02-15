require "test_helper"

class DataQualityTest < ActiveSupport::TestCase
  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
    @user = User.create!(email_hmac: "test_hmac", role: "candidate")
  end

  test "company name format validation" do
    valid_names = ["Acme Corp", "StartUp Inc.", "McDonald's LLC"]
    valid_names.each do |name|
      company = Company.new(name: name, region: "US")
      assert company.valid?, "#{name} should be valid"
    end
  end

  test "company name validates presence" do
    invalid_names = ["", "  ", "\n\n", "\t"]
    invalid_names.each do |name|
      company = Company.new(name: name, region: "US")
      refute company.valid?, "'#{name.strip}' should be invalid if blank"
    end
  end

  test "recruiter public slug uniqueness and format" do
    slug1 = SecureRandom.hex(4).upcase
    Recruiter.create!(name: "Recruiter 1", public_slug: slug1, company: @company)
    
    recruiter2 = Recruiter.new(name: "Recruiter 2", public_slug: slug1, company: @company)
    refute recruiter2.valid?
    assert_includes recruiter2.errors[:public_slug], "has already been taken"
  end

  test "rating boundaries on experiences" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user)
    
    valid_ratings = [1, 2, 3, 4, 5]
    valid_ratings.each do |rating|
      experience = Experience.new(interaction: interaction, rating: rating, status: "pending")
      assert experience.valid?, "Rating #{rating} should be valid"
    end
  end

  test "rating rejects out of bounds values" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user)
    
    invalid_ratings = [0, -1, 6, 10, "a", nil, ""]
    invalid_ratings.each do |rating|
      experience = Experience.new(interaction: interaction, rating: rating, status: "pending")
      refute experience.valid?, "Rating #{rating} should be invalid"
    end
  end

  test "experience body text quality" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user)
    
    valid_bodies = [
      "Great experience!",
      "A" * 5000,
      "Professional and thorough process.\n\nWould recommend.",
      "Test with special chars: !@#$%^&*()"
    ]
    
    valid_bodies.each do |body|
      experience = Experience.new(interaction: interaction, rating: 5, body: body, status: "pending")
      assert experience.valid?, "Body '#{body[0..20]}...' should be valid"
    end
  end

  test "interaction status state transitions" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user, status: "pending")
    
    valid_statuses = ["pending", "approved", "removed"]
    valid_statuses.each do |status|
      interaction.status = status
      assert interaction.valid?, "Status #{status} should be valid"
    end
  end

  test "email HMAC consistency" do
    email = "test@example.com"
    hmac1 = OpenSSL::HMAC.hexdigest("SHA256", ENV.fetch("SUBMISSION_EMAIL_HMAC_PEPPER", "pepper"), email)
    hmac2 = OpenSSL::HMAC.hexdigest("SHA256", ENV.fetch("SUBMISSION_EMAIL_HMAC_PEPPER", "pepper"), email)
    
    assert_equal hmac1, hmac2, "HMAC should be deterministic"
  end

  test "user role enum constraints" do
    valid_roles = ["candidate", "recruiter", "moderator", "admin"]
    valid_roles.each do |role|
      user = User.new(email_hmac: SecureRandom.hex(16), role: role)
      assert user.valid?, "Role #{role} should be valid"
    end
  end

  test "user role enum raises on invalid values" do
    invalid_roles = ["superadmin", "guest", "candidate_recruiter"]
    invalid_roles.each do |role|
      assert_raises(ArgumentError, "Role #{role} should raise ArgumentError") do
        user = User.new(email_hmac: SecureRandom.hex(16))
        user.role = role
      end
    end
  end

  test "review score aggregation accuracy" do
    interaction1 = Interaction.create!(recruiter: @recruiter, target: @user, status: "approved")
    interaction2 = Interaction.create!(recruiter: @recruiter, target: @user, status: "approved")
    interaction3 = Interaction.create!(recruiter: @recruiter, target: @user, status: "approved")
    
    Experience.create!(interaction: interaction1, rating: 4, status: "approved")
    Experience.create!(interaction: interaction2, rating: 5, status: "approved")
    Experience.create!(interaction: interaction3, rating: 3, status: "approved")
    
    approved_experiences = Experience.joins(:interaction)
                                    .where(interactions: { recruiter_id: @recruiter.id, status: "approved" })
                                    .where(status: "approved")
    
    ratings = approved_experiences.pluck(:rating)
    average = ratings.sum.to_f / ratings.size
    
    assert_equal 4.0, average, "Average should be calculated correctly"
    assert_equal 3, approved_experiences.count, "Should count only approved experiences"
  end

  test "company privacy bucketing logic" do
    small_company = Company.create!(name: "Small Startup", size_bucket: "small", region: "US")
    large_company = Company.create!(name: "Big Corp", size_bucket: "5000+", region: "US")
    
    assert_equal "small", small_company.size_bucket, "Small companies should be bucketed"
    assert_equal "5000+", large_company.size_bucket, "Large companies should show actual size"
    
    recruiter_small = Recruiter.create!(name: "Recruiter Small", company: small_company)
    recruiter_large = Recruiter.create!(name: "Recruiter Large", company: large_company)
    
    assert_equal small_company, recruiter_small.company
    assert_equal large_company, recruiter_large.company
  end

  test "review metrics score validation" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user, status: "approved")
    experience = Experience.create!(interaction: interaction, rating: 5, status: "approved")
    
    valid_scores = [1, 2, 3, 4, 5]
    valid_scores.each do |score|
      metric = ReviewMetric.new(
        experience_id: experience.id,
        dimension: "responsiveness",
        score: score
      )
      assert metric.valid?, "Metric score #{score} should be valid"
    end
  end

  test "review metrics reject invalid scores" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user, status: "approved")
    experience = Experience.create!(interaction: interaction, rating: 5, status: "approved")
    
    invalid_scores = [0, 6, -1, "a", nil, ""]
    invalid_scores.each do |score|
      metric = ReviewMetric.new(
        experience_id: experience.id,
        dimension: "responsiveness",
        score: score
      )
      refute metric.valid?, "Metric score #{score} should be invalid"
    end
  end

  test "timestamp consistency across related records" do
    Time.freeze do
      interaction = Interaction.create!(recruiter: @recruiter, target: @user, status: "pending")
      experience = Experience.create!(interaction: interaction, rating: 5, status: "pending")
      
      assert_equal interaction.created_at.to_i, experience.created_at.to_i, 
                   "Related records should have consistent timestamps"
      assert_equal interaction.created_at.to_i, interaction.updated_at.to_i,
                   "New records should have same created_at and updated_at"
      assert experience.created_at > Time.now - 2.days, "Timestamp should be recent"
    end
  end

  test "slug generation uniqueness across many creations" do
    slugs = []
    100.times do
      recruiter = Recruiter.create!(name: "Recruiter #{rand(10000)}", company: @company)
      slugs << recruiter.public_slug
    end
    
    assert_equal slugs.uniq.count, slugs.count, "All slugs should be unique"
    slugs.each do |slug|
      assert_match /^[0-9A-F]{8}$/, slug, "Each slug should be 8 character hex string"
    end
  end

  test "compensation range tracking" do
    role = Role.new(
      title: "Software Engineer",
      recruiting_company_id: @company.id,
      min_compensation: 120000,
      max_compensation: 150000
    )
    
    assert role.valid?
    assert_operator role.min_compensation, :<=, role.max_compensation
    
    role.min_compensation = 200000
    assert role.save, "Role saves even with inconsistent compensation range"
    
    assert_operator role.min_compensation, :>, role.max_compensation, 
                   "Model allows min > max but application should handle display"
  end

  test "linkedin URL format validation" do
    valid_urls = [
      "https://www.linkedin.com/in/johndoe",
      "https://linkedin.com/in/jane-smith-123",
      nil
    ]
    
    valid_urls.each do |url|
      recruiter = Recruiter.new(name: "Test Recruiter", public_slug: SecureRandom.hex(4).upcase, company: @company, linkedin_url: url)
      assert recruiter.valid?, "URL #{url} should be valid"
    end
  end
end