require "test_helper"

class AdminReviewsTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Globex Recruiting", region: "US")
    @recruiter = Recruiter.create!(name: "Ava Tanaka", company: @company, public_slug: "ava-tanaka")
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex(16))
    @review = Review.create!(user: @user, recruiter: @recruiter, company: @company, overall_score: 4, text: "Test review", status: "pending")
  end

  test "requires basic auth" do
    get "/admin/reviews"
    assert_response :unauthorized
  end

  test "renders queue with valid credentials" do
    auth = ActionController::HttpAuthentication::Basic.encode_credentials("mod", "mod")
    get "/admin/reviews", headers: { "HTTP_AUTHORIZATION" => auth }
    assert_response :success
    assert_includes @response.body, I18n.t("admin.reviews.index.title")
  end
end

