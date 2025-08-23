require "test_helper"

class AdminResponsesFlowsTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Acme Talent Group", region: "US")
    @recruiter = Recruiter.create!(name: "Maya Kapoor", company: @company, public_slug: "maya-kapoor")
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex(16))
    @review = Review.create!(user: @user, recruiter: @recruiter, company: @company, overall_score: 4, text: "Moderate me", status: "pending")
  end

  def auth_headers
    { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("mod", "mod") }
  end

  test "create response, hide it, then show it again" do
    # Create response
    assert_difference -> { ReviewResponse.count }, +1 do
      post "/admin/reviews/#{@review.id}/responses", params: { review_response: { body: "Thanks for the feedback." } }, headers: auth_headers
    end
    assert_response :redirect
    resp = ReviewResponse.order(:id).last
    assert_equal true, resp.visible

    # Hide response
    patch "/admin/reviews/#{@review.id}/responses/#{resp.id}/hide", headers: auth_headers
    assert_response :redirect
    assert_equal false, resp.reload.visible

    # Show response
    patch "/admin/reviews/#{@review.id}/responses/#{resp.id}", headers: auth_headers
    assert_response :redirect
    assert_equal true, resp.reload.visible

    # Moderation actions created
    actions = ModerationAction.where(subject_type: "Review", subject_id: @review.id)
    assert actions.where(action: "respond").exists?
    assert actions.where(action: "response_hide").exists?
    assert actions.where(action: "response_show").exists?
  end
end

