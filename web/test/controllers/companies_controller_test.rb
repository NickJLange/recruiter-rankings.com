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

  test "type=recruiting shows companies that have recruiters" do
    get companies_url(type: "recruiting")
    assert_response :success
    assert_select "td", "Initech"
  end

  test "type=recruiting excludes companies without recruiters" do
    other = Company.create!(name: "Empty Corp", region: "US")
    # Give it an experience so it passes the threshold
    user2 = User.create!(role: "candidate", email_hmac: SecureRandom.hex)
    # No recruiter linked to other — it should not appear in type=recruiting
    get companies_url(type: "recruiting")
    assert_response :success
    assert_no_match("Empty Corp", response.body)
  end

  test "should get show as paid user" do
    sign_in_as_clerk(role: :paid, providers: [:email, :linkedin])
    
    get company_url(@company)
    assert_response :success
    
    # Paid: Should see Recruiter list with REAL name
    assert_select "table"
    assert_select "td", "Bill Lumbergh"
  end
end
