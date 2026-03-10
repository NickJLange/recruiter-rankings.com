require "test_helper"

class ClaimIdentityControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    # Assuming we have fixtures or factories.
    # If not, we rely on creating data.
    # We'll create a user and a challenge.
    @user = User.create!(role: 'candidate', email_hmac: 'test_hmac')
    @challenge = IdentityChallenge.create!(
      subject_type: 'User',
      subject_id: @user.id,
      token_hash: 'test_hash',
      expires_at: 1.hour.from_now
    )
  end

  test "verify enqueues job and redirects" do
    assert_enqueued_with(job: VerifyIdentityJob, args: [@challenge.id, "https://linkedin.com/in/test"]) do
      post verify_claim_identity_url, params: { challenge_id: @challenge.id, linkedin_url: "https://linkedin.com/in/test" }
    end

    assert_redirected_to root_path
    assert_match(/queue/i, flash[:notice])
  end

  test "verify with expired challenge" do
    @challenge.update!(expires_at: 1.hour.ago)

    # Based on existing code (not modified by me, except ensuring it's still there),
    # it raises BadRequest or redirects?
    # Original code: raise ActionController::BadRequest, 'Expired' if challenge.expires_at.past?

    post verify_claim_identity_url, params: { challenge_id: @challenge.id, linkedin_url: "https://linkedin.com/in/test" }
    assert_response :bad_request
  end
end
