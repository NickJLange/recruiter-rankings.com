require "application_system_test_case"

class SubscriptionsTest < ApplicationSystemTestCase
  test "user can upgrade to paid" do
    # 1. Setup candidate user
    user = User.create!(role: "candidate", paid: false, email_hmac: SecureRandom.hex)
    # sign_in_as(user) - Incompatible with System Tests (uses direct POST)
    
    # UI Login
    visit login_path
    click_button "Login as #{user.id}"

    # 2. Visit Upgrade Page
    visit new_subscription_path
    assert_selector "h1", text: "Upgrade to Premium"
    assert_selector "h2", text: "Pro Access"

    # 3. Perform Upgrade
    click_button "Upgrade Now (Simulated)"

    # 4. Verify Success
    assert_text "Upgrade successful!"
    assert user.reload.paid?, "User should be marked as paid"
    
    # 5. Verify Access (Spot Check)
    # Assuming one company exists from seeds or we create one
    # But mainly checking the 'paid' bit flip here.
  end

  test "redirects if not logged in" do
    visit new_subscription_path
    assert_selector "h1", text: "Development Login" # Redirects to login
  end
end
