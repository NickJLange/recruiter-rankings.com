require "application_system_test_case"

class ManualVerificationFlowTest < ApplicationSystemTestCase
  test "visitor can register and verify identity with just username" do
    visit "/identity_verifications/new"
    
    fill_in "Email", with: "kenta@example.com"
    fill_in "LinkedIn Profile URL", with: "KentaLange" # Just username
    click_on "Register & Get User Link"
    
    assert_text "Registration submitted. Pending verification."
    assert_text "Status: Pending"
    
    user = User.last
    # Check normalization
    # Allows for optional trailing slash or case sensitivity, but checking per requirement
    assert_match %r{https://www\.linkedin\.com/in/KentaLange/?}, user.linked_in_url
  end

  test "register and see pending status" do
    visit root_path
    click_on "Register / Verify"

    fill_in "Email Address", with: "new_human@example.com"
    fill_in "LinkedIn Profile URL", with: "https://linkedin.com/in/human"
    click_on "Register & Get User Link"

    assert_text "Registration submitted"
    assert_text /User ID \(Slug\): [0-9A-F]{8}/
    assert_text "Status: Pending"
    assert_text "Copy your User Link"
  rescue Capybara::ElementNotFound => e
    puts "Page Body when failure: #{page.body}"
    raise e
  end
end
