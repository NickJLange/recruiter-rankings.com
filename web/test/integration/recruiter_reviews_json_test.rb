require "test_helper"

class RecruiterReviewsJsonTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Globex Recruiting", region: "US")
    @recruiter = Recruiter.create!(name: "Ava Tanaka", company: @company, public_slug: "AAAAAAAA")
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex(16))
    @r1 = Review.create!(user: @user, recruiter: @recruiter, company: @company, overall_score: 5, text: "Excellent", status: "approved")
    @r2 = Review.create!(user: @user, recruiter: @recruiter, company: @company, overall_score: 3, text: "Okay", status: "approved")
  end

  test "reviews json returns recent approved reviews with fields" do
    get "/person/AAAAAAAA/reviews.json", params: { per: 1 }
    assert_response :success
    arr = JSON.parse(@response.body)
    assert_kind_of Array, arr
    assert_equal 1, arr.length
    item = arr.first
    assert item.key?("id")
    assert item.key?("overall_score")
    assert item.key?("text")
    assert item.key?("created_at")
  end
end

