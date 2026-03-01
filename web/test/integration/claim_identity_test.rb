require "test_helper"

class ClaimIdentityTest < ActionDispatch::IntegrationTest
  setup do
    @company   = Company.create!(name: "Recruiter Firm", region: "US")
    @recruiter = Recruiter.create!(
      name: "Jo Recruiter",
      company: @company,
      public_slug: "jo-recruiter-test"
    )
  end

  # --- create ---

  test "POST /claim_identity renders instructions page" do
    post "/claim_identity", params: {
      claim: {
        subject_type:   "recruiter",
        recruiter_slug: @recruiter.public_slug,
        linkedin_url:   "https://linkedin.com/in/jo-recruiter"
      }
    }
    assert_response :success
    assert_match(/RR-VERIFY-/i, response.body)
  end

  test "create persists linkedin_url on recruiter when blank" do
    assert_nil @recruiter.reload.linkedin_url

    post "/claim_identity", params: {
      claim: {
        subject_type:   "recruiter",
        recruiter_slug: @recruiter.public_slug,
        linkedin_url:   "https://linkedin.com/in/jo-recruiter"
      }
    }
    assert_response :success
    assert_equal "https://linkedin.com/in/jo-recruiter", @recruiter.reload.linkedin_url
  end

  test "create does not overwrite existing linkedin_url" do
    @recruiter.update!(linkedin_url: "https://linkedin.com/in/original")

    post "/claim_identity", params: {
      claim: {
        subject_type:   "recruiter",
        recruiter_slug: @recruiter.public_slug,
        linkedin_url:   "https://linkedin.com/in/new-url"
      }
    }
    assert_response :success
    assert_equal "https://linkedin.com/in/original", @recruiter.reload.linkedin_url
  end

  test "create shows pending-review notice without a Verify button" do
    post "/claim_identity", params: {
      claim: {
        subject_type:   "recruiter",
        recruiter_slug: @recruiter.public_slug,
        linkedin_url:   "https://linkedin.com/in/jo-recruiter"
      }
    }
    assert_response :success
    assert_match(/admin will verify/i, response.body)
    # No standalone Verify submit button
    assert_select "button", text: /\AVerify\z/i, count: 0
    assert_select "form[action*='verify']", count: 0
  end

  test "create creates an IdentityChallenge record" do
    assert_difference "IdentityChallenge.count", 1 do
      post "/claim_identity", params: {
        claim: {
          subject_type:   "recruiter",
          recruiter_slug: @recruiter.public_slug,
          linkedin_url:   "https://linkedin.com/in/jo-recruiter"
        }
      }
    end
  end

  test "create with unknown recruiter slug renders form with error" do
    post "/claim_identity", params: {
      claim: {
        subject_type:   "recruiter",
        recruiter_slug: "no-such-slug",
        linkedin_url:   "https://linkedin.com/in/nobody"
      }
    }
    assert_response :unprocessable_entity
    assert_match(/recruiter not found/i, response.body)
  end

  # --- verify ---

  test "POST /claim_identity/verify redirects with pending notice" do
    challenge = IdentityChallenge.create!(
      subject:    @recruiter,
      token:      "RR-VERIFY-abc123",
      token_hash: Digest::SHA256.hexdigest("abc123"),
      expires_at: 7.days.from_now
    )

    post "/claim_identity/verify", params: {
      challenge_id: challenge.id,
      linkedin_url: "https://linkedin.com/in/jo-recruiter"
    }
    assert_redirected_to root_path
    assert_match(/queue/i, flash[:notice])
  end
end
