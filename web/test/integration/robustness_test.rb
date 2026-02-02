require "test_helper"
require "faker"

class RobustnessTest < ActionDispatch::IntegrationTest
  setup do
    # Generate some messy data for this test run
    @company = Company.create!(
      name: Faker::Company.unique.name,
      size_bucket: "Small company",
      website_url: Faker::Internet.url,
      region: "Remote"
    )
    ENV["PUBLIC_MIN_REVIEWS"] = "1"
    
    @recruiter = Recruiter.create!(
      name: Faker::Name.unique.name,
      company: @company,
      public_slug: "DEADBEEF", # Valid 8-char hex
      region: "Remote",
      verified_at: nil, # Unverified
      email_hmac: nil   # No email
    )
    
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex)
    
    # Create a review with very long text and missing metrics
    i = Interaction.create!(recruiter: @recruiter, target: @user, occurred_at: Time.now, status: "approved")
    @experience = Experience.create!(
      interaction: i,
      rating: 1,
      body: Faker::Lorem.paragraphs(number: 10).join("\n\n"),
      status: "approved"
    )
    # No metrics created for this review to test partial data handling
  end

  test "recruiters index handles diverse data" do
    get "/person"
    assert_response :success
    assert_select ".recruiter-row", count: 2
  end

  test "recruiter profile handles missing metrics and long text" do
    get "/person/#{@recruiter.public_slug}"
    assert_response :success
    # Name should be masked for anonymous user
    assert_select "h1", /Recruiter .+/
    # Text should be HIDDEN for anonymous user
    assert_select ".review-text", false
    
    # Create and sign in as paid user
    paid_user = User.create!(role: "candidate", paid: true, email_hmac: SecureRandom.hex)
    sign_in_as(paid_user)
    
    get "/person/#{@recruiter.public_slug}"
    assert_response :success
    # Name should be visible
    assert_select "h1", @recruiter.name
    # Should not crash even if metrics are missing, and text should be visible
    assert_select ".review-text"
  end

  test "companies index handles diverse data" do
    get "/companies"
    assert_response :success
  end
end
