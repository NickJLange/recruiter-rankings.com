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
    
    @recruiter = Recruiter.create!(
      name: Faker::Name.unique.name,
      company: @company,
      public_slug: Faker::Internet.slug,
      region: "Remote",
      verified_at: nil, # Unverified
      email_hmac: nil   # No email
    )
    
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex)
    
    # Create a review with very long text and missing metrics
    @review = Review.create!(
      user: @user,
      recruiter: @recruiter,
      company: @company,
      overall_score: 1,
      text: Faker::Lorem.paragraphs(number: 10).join("\n\n"),
      status: "approved"
    )
    # No metrics created for this review to test partial data handling
  end

  test "recruiters index handles diverse data" do
    get "/recruiters"
    assert_response :success
    assert_select ".recruiter-row", count: 10
  end

  test "recruiter profile handles missing metrics and long text" do
    get "/recruiters/#{@recruiter.public_slug}"
    assert_response :success
    assert_select "h1", @recruiter.name
    # Should not crash even if metrics are missing
    assert_select ".review-text"
  end

  test "companies index handles diverse data" do
    get "/companies"
    assert_response :success
  end
end
