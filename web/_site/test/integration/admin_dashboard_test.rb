require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  def auth_headers
    { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("mod", "mod") }
  end

  setup do
    @company = Company.create!(name: "Acme", region: "US")
    @recruiter = Recruiter.create!(name: "Diego Fernández", company: @company, public_slug: "diego-fernandez")
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex(16))
    Review.create!(user: @user, recruiter: @recruiter, company: @company, overall_score: 4, text: "Pending", status: "pending")
    Review.create!(user: @user, recruiter: @recruiter, company: @company, overall_score: 2, text: "Flag me", status: "flagged")
    r = Review.create!(user: @user, recruiter: @recruiter, company: @company, overall_score: 5, text: "Approved", status: "approved")
    ReviewResponse.create!(review: r, body: "Hidden reply", visible: false)
    ModerationAction.create!(actor: nil, action: "dummy", subject_type: "Review", subject_id: r.id, notes: "test")
    IdentityChallenge.create!(subject_type: "User", subject_id: @user.id, token_hash: SecureRandom.hex(8), expires_at: 1.day.from_now, verified_at: nil)
  end

  test "dashboard requires auth" do
    get "/admin"
    assert_response :unauthorized
  end

  test "dashboard renders metrics and links with auth" do
    get "/admin", headers: auth_headers
    assert_response :success
    assert_includes @response.body, "Admin Dashboard"
    assert_includes @response.body, "Pending reviews"
    assert_includes @response.body, "Flagged reviews"
    assert_includes @response.body, "Hidden responses"
    assert_includes @response.body, "Recent moderation actions"
  end
end

