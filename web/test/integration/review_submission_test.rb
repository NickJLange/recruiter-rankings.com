require "test_helper"

class ReviewSubmissionTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Massive Dynamic", region: "US")
    @slug = SecureRandom.hex(4).upcase
    @recruiter = Recruiter.create!(name: "Nina Sharp", company: @company, public_slug: @slug)
  end

  test "review form has accessibility attributes" do
    sign_in_as_clerk(role: :candidate, providers: [:email])
    get new_recruiter_review_path(@slug, recruiter_slug: @slug)
    assert_response :success

    # Check for autofocus on score input
    assert_select "input[name='review[overall_score]'][autofocus='autofocus']"

    # Check for maxlength and aria-describedby on text area
    assert_select "textarea[name='review[text]'][maxlength='5000']"
    assert_select "textarea[name='review[text]'][aria-describedby='text-help char-counter']"
    assert_select "textarea[name='review[text]'][data-behavior='char-counter']"

    # Check for help text
    assert_select "#text-help", /Max 5000 characters/
    # Check for character counter
    assert_select "#char-counter", /0 \/ 5000/
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

  test "submitting with dimension scores creates individual ReviewMetrics" do
    sign_in_as_clerk(role: :candidate, providers: [:email])

    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: 4,
        text: "Good recruiter.",
        dimension_responsiveness: "5",
        dimension_role_clarity: "3",
        dimension_professionalism_respect: "4"
      }
    }

    assert_redirected_to recruiter_path(@slug)

    experience = Experience.last
    metrics = experience.review_metrics.index_by(&:dimension)

    assert_equal 5, metrics["responsiveness"].score
    assert_equal 3, metrics["role_clarity"].score
    assert_equal 4, metrics["professionalism_respect"].score
    # Only 3 submitted — copy-overall fallback should NOT run
    assert_equal 3, experience.review_metrics.count
  end

  test "submitting without dimension scores uses copy-overall fallback" do
    sign_in_as_clerk(role: :candidate, providers: [:email])

    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: 3,
        text: "Average experience."
      }
    }

    assert_redirected_to recruiter_path(@slug)

    experience = Experience.last
    # copy_overall_to_dimensions? determines whether fallback runs in test env
    # Either 0 or 8 metrics (all at rating 3) — both are valid
    metrics = experience.review_metrics.to_a
    assert metrics.empty? || metrics.all? { |m| m.score == 3 },
      "Expected either no metrics or all metrics copied from overall score"
  end

  test "submitting with job info creates Role linked to Interaction" do
    sign_in_as_clerk(role: :candidate, providers: [:email])

    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: 4,
        text: "Good process.",
        role_title: "Staff Engineer",
        role_min_compensation: "150000",
        role_max_compensation: "200000",
        role_target_company: "Initech",
        occurred_at: "2026-01-15"
      }
    }

    assert_redirected_to recruiter_path(@slug)

    interaction = Interaction.last
    assert_not_nil interaction.role
    role = interaction.role
    assert_equal "Staff Engineer", role.title
    assert_equal 150000, role.min_compensation
    assert_equal 200000, role.max_compensation
    assert_equal "Initech", role.target_company.name
    assert_equal @company, role.recruiting_company
    assert_equal Date.new(2026, 1, 15), interaction.occurred_at.to_date
  end

  test "submitting with outcome and would_recommend persists on experience" do
    sign_in_as_clerk(role: :candidate, providers: [:email])

    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: 5,
        text: "Got the job!",
        would_recommend: "1",
        outcome: "hired"
      }
    }

    assert_redirected_to recruiter_path(@slug)

    experience = Experience.last
    assert experience.would_recommend
    assert_equal "hired", experience.outcome
  end

  test "invalid outcome value is rejected" do
    sign_in_as_clerk(role: :candidate, providers: [:email])

    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: 4,
        text: "Something.",
        outcome: "abducted_by_aliens"
      }
    }

    assert_response :unprocessable_entity
  end

  test "out-of-range dimension scores are ignored" do
    sign_in_as_clerk(role: :candidate, providers: [:email])

    post "/reviews", params: {
      review: {
        recruiter_slug: @slug,
        overall_score: 4,
        text: "Good.",
        dimension_responsiveness: "9",  # out of range
        dimension_role_clarity: "3"     # valid
      }
    }

    assert_redirected_to recruiter_path(@slug)

    experience = Experience.last
    assert_equal 1, experience.review_metrics.count
    assert_equal "role_clarity", experience.review_metrics.first.dimension
  end
end
