require "application_system_test_case"

class VerificationFlowTest < ApplicationSystemTestCase
  setup do
    @company = Company.create!(name: "Initech", region: "US")
    @recruiter = Recruiter.create!(name: "Peter Gibbons", company: @company, public_slug: "ABCDEF99")
    
    # Create interactions for checking logic
    @paid_user = User.create!(role: "candidate", email_hmac: "paid_hmac")
    @review = Interaction.create!(recruiter: @recruiter, target: @paid_user, status: "approved", occurred_at: Time.now)
    Experience.create!(interaction: @review, rating: 5, body: "This is a detailed review text used for verification.", status: "approved")
  end

  test "anonymous user flow" do
    visit recruiter_path(@recruiter)

    assert_selector "h1", text: /Recruiter .+/
    assert_no_text "Peter Gibbons"

    assert_no_text "This is a detailed review text"
    assert_text "Detailed reviews are available"
  end

  test "paid user flow" do
    sign_in_as_clerk(role: :paid, providers: [:email])

    visit recruiter_path(@recruiter)

    assert_selector "h1", text: "Peter Gibbons"
    assert_text "This is a detailed review text"
  end
end
