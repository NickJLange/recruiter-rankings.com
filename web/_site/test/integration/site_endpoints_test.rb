require "test_helper"

class SiteEndpointsTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Initech Staffing", region: "US")
    @recruiter = Recruiter.create!(name: "Sora Watanabe", company: @company, public_slug: "sora-watanabe")
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex(16))
    @review = Review.create!(user: @user, recruiter: @recruiter, company: @company, overall_score: 4, text: "Great process", status: "approved")
    # minimal metrics
    ReviewMetric::DIMENSIONS.keys.first(2).each do |dim|
      Review.create unless @review.persisted?
      ReviewMetric.where(review: @review, dimension: dim).first_or_create!(score: 4)
    end
  end

  test "root responds" do
    get "/"
    assert_response :success
  end

  test "recruiters index responds" do
    get "/recruiters"
    assert_response :success
  end

  test "recruiter profile responds" do
    get "/recruiters/sora-watanabe"
    assert_response :success
  end

  test "recruiter json responds" do
    get "/recruiters/sora-watanabe.json"
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

