require "test_helper"
require "minitest/mock"

class RegistrationFlowsTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Cyberdyne Systems", region: "US")
    @recruiter = Recruiter.create!(name: "Miles Dyson", company: @company, public_slug: "miles-dyson")
  end

  test "recruiter claim flow" do
    # 1. Submit claim request
    post "/claim_identity", params: {
      claim: {
        subject_type: "recruiter",
        recruiter_slug: "miles-dyson",
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
    
    # Create a mock fetcher that returns the token in the response
    mock_fetcher = Minitest::Mock.new
    mock_fetcher.expect(:fetch, "<html><body>Profile content with #{token}</body></html>", [String])
    
    # Inject the mock into the controller
    ClaimIdentityController.any_instance.stub(:linkedin_fetcher, mock_fetcher) do
      post "/claim_identity/verify", params: {
        challenge_id: challenge.id,
        linkedin_url: "https://linkedin.com/in/miles"
      }

      assert_redirected_to recruiter_path("miles-dyson")
      follow_redirect!
      assert_select ".alert-info", "Recruiter verified."
      
      assert @recruiter.reload.verified_at.present?
    end
    
    # Verify the mock was called
    mock_fetcher.verify
  end

  test "user review submission creates user" do
    email = "newuser@example.com"
    
    assert_nil User.find_by_email_hmac(OpenSSL::HMAC.hexdigest("SHA256", submission_email_hmac_pepper, email))

    post "/reviews", params: {
      review: {
        recruiter_slug: "miles-dyson",
        overall_score: 5,
        text: "Great recruiter!",
        email: email
      }
    }

    assert_redirected_to recruiter_path("miles-dyson")
    
    # Verify user created
    # We need to calculate HMAC to find the user
    pepper = submission_email_hmac_pepper
    hmac = OpenSSL::HMAC.hexdigest("SHA256", pepper, email)
    user = User.find_by(email_hmac: hmac)
    
    assert_not_nil user
    assert_equal "candidate", user.role
  end
  
  private
  
  def submission_email_hmac_pepper
    ENV.fetch("SUBMISSION_EMAIL_HMAC_PEPPER", "test-pepper")
  end
end
