require "test_helper"

class AdminReviewsTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Globex Recruiting", region: "US")
    @recruiter = Recruiter.create!(name: "Ava Tanaka", company: @company, public_slug: "ava-tanaka-#{SecureRandom.hex(4)}")
    @user = User.create!(role: "candidate", email_hmac: SecureRandom.hex(16))
    @review = Review.create!(user: @user, recruiter: @recruiter, company: @company, overall_score: 4, text: "Test review", status: "pending")
  end

  test "unauthenticated access redirects to sign-in" do
    get "/admin/reviews"
    assert_response :redirect
  end

  test "renders queue for authenticated admin" do
    sign_in_as_clerk(role: :admin, providers: [:email, :linkedin, :github], two_factor: true)
    get "/admin/reviews"
    assert_response :success
    assert_includes @response.body, I18n.t("admin.reviews.index.title")
  end

  test "can approve a pending review" do
    sign_in_as_clerk(role: :admin, providers: [:email, :linkedin, :github], two_factor: true)

    assert_equal "pending", @review.status

    patch "/admin/reviews/#{@review.id}/approve"

    assert_redirected_to admin_reviews_path
    assert_equal "approved", @review.reload.status
  end

  test "can flag a review" do
    sign_in_as_clerk(role: :admin, providers: [:email, :linkedin, :github], two_factor: true)

    patch "/admin/reviews/#{@review.id}/flag"

    assert_redirected_to admin_reviews_path
    assert_equal "flagged", @review.reload.status
  end
end
