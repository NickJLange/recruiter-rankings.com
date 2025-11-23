require "test_helper"

class ReviewSubmissionTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Massive Dynamic", region: "US")
    @slug = "nina-sharp-#{SecureRandom.hex(4)}"
    @recruiter = Recruiter.create!(name: "Nina Sharp", company: @company, public_slug: @slug)
  end

  test "can submit a review" do
    get "/recruiters/#{@slug}"
    assert_response :success

    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: 5,
        text: "Fantastic experience!",
        email: "candidate@example.com"
      }
    }

    assert_redirected_to recruiter_path(@slug)
    follow_redirect!
    assert_response :success
    assert_select ".alert-info", /Thanks! Your review has been submitted./
    
    # Verify review was created
    review = Review.last
    assert_equal @slug, review.recruiter.public_slug
    assert_equal 5, review.overall_score
    assert_equal "Fantastic experience!", review.text
  end

  test "invalid submission shows errors" do
    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: "", # Invalid
        text: "",
        email: "candidate@example.com"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".alert-danger", /Please correct the errors below./
  end
end
