require "test_helper"
require "minitest/mock"

class RegistrationFlowsTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Cyberdyne Systems", region: "US")
    @recruiter = Recruiter.create!(name: "Miles Dyson", company: @company, public_slug: "A1B2C3D4")
  end

  test "recruiter claim flow" do
    # 1. Submit claim request
    post "/claim_identity", params: {
      claim: {
        subject_type: "recruiter",
        recruiter_slug: "A1B2C3D4",
        linkedin_url: "https://linkedin.com/in/miles",
        email: "miles@example.com"
      }
    }

    assert_response :success
    assert_select "h1", "Verification instructions"

    # Extract challenge ID from the form or URL (simulated here by querying DB)
    challenge = IdentityChallenge.last
    assert_equal "Recruiter", challenge.subject_type
    assert_equal @recruiter.id, challenge.subject_id

    # 2. Verify claim (Mocking LinkedInFetcher to return the token)
    token = "RR-VERIFY-#{challenge.token_hash}"

    # Stub LinkedinFetcher.new to return a mock that yields the token
    mock_fetcher = Minitest::Mock.new
    mock_fetcher.expect(:fetch, "<html><body>Profile content with #{token}</body></html>", [String])

    LinkedinFetcher.stub(:new, mock_fetcher) do
      post "/claim_identity/verify", params: {
        challenge_id: challenge.id,
        linkedin_url: "https://linkedin.com/in/miles"
      }

      assert_redirected_to recruiter_path("A1B2C3D4")
      follow_redirect!
      assert_select ".alert-info", "Recruiter verified."

      assert @recruiter.reload.verified_at.present?
    end

    mock_fetcher.verify
  end

  test "review submission creates user record for clerk identity" do
    clerk_user_id = "user_test_#{SecureRandom.hex(8)}"
    sign_in_as_clerk(role: :candidate, providers: [:email], user_id: clerk_user_id)

    assert_nil User.find_by(clerk_user_id: clerk_user_id)

    post "/reviews", params: {
      review: {
        recruiter_slug: "A1B2C3D4",
        overall_score: 5,
        text: "Great recruiter!"
      }
    }

    assert_redirected_to recruiter_path("A1B2C3D4")

    user = User.find_by(clerk_user_id: clerk_user_id)
    assert_not_nil user
    assert_equal "candidate", user.role
  end
end
