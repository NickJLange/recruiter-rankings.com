require "test_helper"

class ReviewSubmissionTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Massive Dynamic", region: "US")
    @slug = SecureRandom.hex(4).upcase
    @recruiter = Recruiter.create!(name: "Nina Sharp", company: @company, public_slug: @slug)
  end

  test "can submit a review" do
    sign_in_as_clerk(role: :candidate, providers: [:email])

    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: 5,
        text: "Fantastic experience!"
      }
    }

    assert_redirected_to recruiter_path(@slug)
    follow_redirect!
    assert_response :success
    assert_select ".alert-info", /Thanks! Your review has been submitted./

    experience = Experience.last
    assert_equal @slug, experience.interaction.recruiter.public_slug
    assert_equal 5, experience.rating
    assert_equal "Fantastic experience!", experience.body
  end

  test "invalid submission shows errors" do
    sign_in_as_clerk(role: :candidate, providers: [:email])

    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: "", # Invalid
        text: ""
      }
    }

    assert_response :unprocessable_entity
    assert_select ".alert-danger", /Please correct the errors below./
  end

  test "unauthenticated user cannot submit review" do
    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: 5,
        text: "Great!"
      }
    }

    assert_response :redirect
  end
end
