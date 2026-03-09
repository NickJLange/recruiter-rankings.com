require "test_helper"

# Tests the AuthPolicy concern and AuthenticationService#meets_requirements?
# through the full HTTP request cycle.
class AuthPolicyTest < ActionDispatch::IntegrationTest
  setup do
    @company   = Company.create!(name: "Test Corp", region: "US")
    @slug      = SecureRandom.hex(4).upcase
    @recruiter = Recruiter.create!(name: "Jane Doe", company: @company, public_slug: @slug)
  end

  # --- candidate_submit policy (POST /reviews) ---

  test "candidate_submit: email provider allows review submission" do
    sign_in_as_clerk(role: :candidate, providers: [:email])
    post "/reviews", params: { review: { recruiter_slug: @slug, overall_score: 4, text: "Good recruiter" } }
    assert_redirected_to recruiter_path(@slug)
  end

  test "candidate_submit: linkedin provider allows review submission" do
    sign_in_as_clerk(role: :candidate, providers: [:linkedin])
    post "/reviews", params: { review: { recruiter_slug: @slug, overall_score: 4, text: "Good recruiter" } }
    assert_redirected_to recruiter_path(@slug)
  end

  test "candidate_submit: no providers redirects with alert" do
    sign_in_as_clerk(role: :candidate, providers: [])
    post "/reviews", params: { review: { recruiter_slug: @slug, overall_score: 4, text: "Good recruiter" } }
    assert_response :redirect
    assert_match /Please connect the required accounts/, flash[:alert]
  end

  test "unauthenticated user cannot submit review" do
    post "/reviews", params: { review: { recruiter_slug: @slug, overall_score: 4, text: "Sneaky" } }
    assert_response :redirect
  end

  # --- admin policy (GET /admin) ---

  test "admin: full credentials allow access" do
    sign_in_as_clerk(role: :admin, providers: [:email, :linkedin, :github], two_factor: true)
    get "/admin"
    assert_response :success
  end

  test "admin: missing github redirects with alert" do
    sign_in_as_clerk(role: :admin, providers: [:email, :linkedin], two_factor: true)
    get "/admin"
    assert_response :redirect
    assert_match /Please connect the required accounts/, flash[:alert]
  end

  test "admin: missing 2FA redirects with alert" do
    sign_in_as_clerk(role: :admin, providers: [:email, :linkedin, :github], two_factor: false)
    get "/admin"
    assert_response :redirect
    assert_match /Please connect the required accounts/, flash[:alert]
  end

  test "admin: unauthenticated redirects" do
    get "/admin"
    assert_response :redirect
  end

  # --- public routes (no auth required) ---

  test "GET /person is publicly accessible" do
    get "/person"
    assert_response :success
  end

  test "GET /companies is publicly accessible" do
    get "/companies"
    assert_response :success
  end

  test "GET /up health check is publicly accessible" do
    get "/up"
    assert_response :success
  end
end
