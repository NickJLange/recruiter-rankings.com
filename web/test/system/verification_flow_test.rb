require "application_system_test_case"

class VerificationFlowTest < ApplicationSystemTestCase
  setup do
    @company = Company.create!(name: "Initech", region: "US")
    @recruiter = Recruiter.create!(name: "Peter Gibbons", company: @company, public_slug: "ABCDEF99")
    
    # Create interactions for checking logic
    @paid_user = User.create!(role: "candidate", paid: true, public_slug: "DEADBEEF", email_hmac: "paid_hmac")
    @review = Interaction.create!(recruiter: @recruiter, target: @paid_user, status: "approved", occurred_at: Time.now)
    Experience.create!(interaction: @review, rating: 5, body: "This is a detailed review text used for verification.", status: "approved")
  end

  test "anonymous user flow" do
    visit "/person"
    
    # 1. Check Top Companies (NavBar)
    assert_selector "#top-companies-nav li", wait: 5
    
    # 2. Visit Recruiter Profile
    visit recruiter_path(@recruiter)
    
    # 3. Verify Masked Name
    assert_selector "h1", text: /Recruiter .+/
    assert_no_text "Peter Gibbons"
    
    # 4. Verify Review Text Hidden
    assert_no_text "This is a detailed review text"
    assert_text "Detailed reviews are available"
  end

  test "paid user flow" do
    # Simulate Login (using test helper backdoor)
    visit "/utils/login?user_id=#{@paid_user.id}"
    
    # 1. Visit Recruiter Profile
    visit recruiter_path(@recruiter)
    
    # 2. Verify Real Name Visible
    assert_selector "h1", text: "Peter Gibbons"
    
    # 3. Verify Review Text Visible
    assert_text "This is a detailed review text"
  end
end
