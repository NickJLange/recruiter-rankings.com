require "test_helper"

class DevelopmentAuthTest < ActionDispatch::IntegrationTest
  # The old session-based dev login (/login, /logout) is being removed as part of
  # the Clerk auth migration. These routes still exist in dev/test for system test
  # compatibility, but the session[:user_id] pattern is no longer the auth mechanism.
  # This test verifies the routes respond correctly during the transition.

  test "dev login route is accessible in test environment" do
    get "/login"
    assert_response :success
    assert_select "h1", "Development Login"
  end

  test "dev login sets session user_id" do
    user = User.create!(role: "candidate", email_hmac: SecureRandom.hex)
    post "/login", params: { user_id: user.id }
    assert_redirected_to root_path
    assert_equal user.id, session[:user_id]
  end

  test "dev logout clears session" do
    user = User.create!(role: "candidate", email_hmac: SecureRandom.hex)
    post "/login", params: { user_id: user.id }
    delete "/logout"
    assert_redirected_to root_path
    assert_nil session[:user_id]
  end
end
