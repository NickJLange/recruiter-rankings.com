require "application_system_test_case"

class SubscriptionsTest < ApplicationSystemTestCase
  test "user can upgrade to paid" do
    user = User.create!(role: "candidate", paid: false,
                        email_hmac: SecureRandom.hex, clerk_user_id: "user_sub_test_01")
    sign_in_as_clerk(role: :candidate, providers: [:email], user_id: "user_sub_test_01")

    visit new_subscription_path
    assert_selector "h1", text: "Upgrade to Premium"

    click_button "Upgrade Now (Simulated)"

    assert_text "Upgrade successful! (Fake Processor)"
    assert user.reload.paid?, "User should be marked as paid after upgrade"
  end

  test "redirects if not logged in" do
    visit new_subscription_path
    assert_no_text "Upgrade to Premium"
  end
end
