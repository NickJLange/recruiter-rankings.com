require "test_helper"

class ReviewsPaginationLimitTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Globex Recruiting", region: "US")
    @recruiter = Recruiter.create!(name: "Pagination Tester", company: @company, public_slug: "pagination-tester")
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex(16))

    # Create 55 approved reviews
    55.times do |i|
      Review.create!(
        user: @user,
        recruiter: @recruiter,
        company: @company,
        overall_score: 5,
        text: "Review #{i}",
        status: "approved"
      )
    end
  end

  test "reviews list honors public_max_per_page limit" do
    # Request 100 items, more than exists (55) and more than limit (50)
    get "/person/pagination-tester/reviews.json", params: { per: 100 }
    assert_response :success

    reviews = JSON.parse(@response.body)

    # We expect capped at public_max_per_page (50)
    max_limit = (ENV["PUBLIC_MAX_PER_PAGE"].presence || 50).to_i

    assert_operator reviews.length, :<=, max_limit, "Response should not exceed max limit of #{max_limit}, but got #{reviews.length}"
  end
end
