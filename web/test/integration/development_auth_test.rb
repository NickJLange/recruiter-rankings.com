require "test_helper"

class DevelopmentAuthTest < ActionDispatch::IntegrationTest
  test "dev login flow works" do
    # Using existing fixture or creating one
    user = User.create!(role: "candidate", email_hmac: SecureRandom.hex)
    
    # 1. Access New Session Page
    get "/login"
    assert_response :success
    assert_select "h1", "Development Login"
    
    # 2. Perform Login
    post "/login", params: { user_id: user.id }
    assert_redirected_to root_path
    follow_redirect!
    
    # 3. Verify Session and Navbar
    assert_equal user.id, session[:user_id]
    assert_select "span", text: /Logged in as Candidate/
    
    # 4. Perform Logout
    delete "/logout"
    assert_redirected_to root_path
    follow_redirect!
    assert_nil session[:user_id]
    assert_select "a", text: "Dev Login"
  end
end
