require "test_helper"

class CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Initech", region: "US")
    @recruiter = Recruiter.create!(name: "Bill Lumbergh", company: @company, public_slug: "bill-lumbergh")
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex)
    
    # Needs at least one experience to be listed if threshold > 0
    # Assuming threshold is 1 in dev/test for now (set in ApplicationController.public_min_reviews fallback or ENV)
    ENV["PUBLIC_MIN_REVIEWS"] = "1"
    
    i1 = Interaction.create!(recruiter: @recruiter, target: @user, occurred_at: Time.now, status: "approved")
    Experience.create!(interaction: i1, rating: 1, body: "Umm yeah", status: "approved")
  end

  test "should get index" do
    get companies_url
    assert_response :success
    assert_select "td", "Initech"
  end

  test "should get index json" do
    get companies_url(format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_empty json
    item = json.find { |c| c["name"] == "Initech" }
    assert item, "Should find Initech in the response"
    assert_equal 1, item["reviews_count"]
  end

  test "should get show as anonymous" do
    get company_url(@company)
    assert_response :success
    assert_select "h1", "Initech"
    
    # Anonymous: Should see Chart canvas, NOT table list
    assert_select "canvas#trendsChart"
    assert_select "h2", "Role Trends"
    assert_select "table", false, "Recruiter list should be hidden for anonymous users"
  end

  test "should get show as paid user" do
    paid_user = User.create!(role: "candidate", paid: true, email_hmac: SecureRandom.hex)
    sign_in_as(paid_user)
    
    get company_url(@company)
    assert_response :success
    
    # Paid: Should see Recruiter list with REAL name
    assert_select "table"
    assert_select "td", "Bill Lumbergh"
  end
end
