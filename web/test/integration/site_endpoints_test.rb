require "test_helper"

class SiteEndpointsTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Initech Staffing", region: "US")
    @recruiter = Recruiter.create!(name: "Sora Watanabe", company: @company, public_slug: "sora-watanabe")
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex(16))
    
    @role = Role.create!(
      title: "Software Engineer",
      recruiting_company: @company,
      target_company: @company,
      min_compensation: 120000,
      max_compensation: 150000,
      posted_date: Date.today
    )
    
    @interaction = Interaction.create!(
      recruiter: @recruiter,
      target: @user,
      occurred_at: 1.month.ago,
      status: "approved",
      role: @role
    )
    
    @experience = Experience.create!(
      interaction: @interaction,
      rating: 4,
      body: "Great process",
      status: "approved",
      would_recommend: true
    )

    # minimal metrics
    ReviewMetric::DIMENSIONS.keys.first(2).each do |dim|
      ReviewMetric.create!(experience: @experience, dimension: dim, score: 4)
    end
  end

  test "root responds" do
    get "/"
    assert_response :success
  end

  test "recruiters index responds" do
    get "/person"
    assert_response :success
  end

  test "recruiter profile responds" do
    get "/person/#{@recruiter.public_slug}"
    assert_response :success
  end

  test "recruiter json responds" do
    get "/person/#{@recruiter.public_slug}.json"
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "sora-watanabe", body["slug"]
    assert_equal @company.name, body["company"]
  end

  test "companies index and json respond" do
    get "/companies"
    assert_response :success
    get "/companies.json?per=5"
    assert_response :success
    arr = JSON.parse(@response.body)
    assert arr.is_a?(Array)
  end

  test "company show responds" do
    get "/companies/#{@company.id}"
    assert_response :success
  end
end

