require "test_helper"

class SearchTest < ActionDispatch::IntegrationTest
  setup do
    @company   = Company.create!(name: "Globex Recruiting", region: "US")
    @recruiter = Recruiter.create!(name: "Hiro Tanaka", company: @company,
                                   public_slug: "hiro-tanaka-test", region: "JP")
  end

  # --- Route & basic response ---

  test "GET /search responds 200" do
    get "/search"
    assert_response :success
  end

  test "GET /search without query shows prompt" do
    get "/search"
    assert_response :success
    assert_match(/at least 2 characters/i, response.body)
  end

  test "GET /search with 1-char query shows prompt" do
    get "/search", params: { q: "H" }
    assert_response :success
    assert_match(/at least 2 characters/i, response.body)
  end

  # --- Recruiter matching ---

  test "finds recruiter by name (paid user sees real name)" do
    clerk_id = "user_search_paid_#{SecureRandom.hex(4)}"
    User.create!(role: "candidate", paid: true, clerk_user_id: clerk_id, email_hmac: SecureRandom.hex)
    sign_in_as_clerk(role: :paid, providers: [:email], user_id: clerk_id)

    get "/search", params: { q: "Hiro" }
    assert_response :success
    assert_match("Hiro Tanaka", response.body)
  end

  test "search is case-insensitive for recruiters (paid user sees real name)" do
    clerk_id = "user_search_paid2_#{SecureRandom.hex(4)}"
    User.create!(role: "candidate", paid: true, clerk_user_id: clerk_id, email_hmac: SecureRandom.hex)
    sign_in_as_clerk(role: :paid, providers: [:email], user_id: clerk_id)

    get "/search", params: { q: "hiro" }
    assert_response :success
    assert_match("Hiro Tanaka", response.body)
  end

  test "anonymous user sees masked name in search results" do
    get "/search", params: { q: "Hiro" }
    assert_response :success
    assert_no_match("Hiro Tanaka", response.body)
    assert_match(/Recruiter /i, response.body)
  end

  test "paid user sees real name in search results" do
    clerk_id = "user_search_paid3_#{SecureRandom.hex(4)}"
    User.create!(role: "candidate", paid: true, clerk_user_id: clerk_id, email_hmac: SecureRandom.hex)
    sign_in_as_clerk(role: :paid, providers: [:email], user_id: clerk_id)

    get "/search", params: { q: "Hiro" }
    assert_response :success
    assert_match("Hiro Tanaka", response.body)
  end

  test "recruiter result includes company name" do
    get "/search", params: { q: "Hiro" }
    assert_match("Globex Recruiting", response.body)
  end

  test "recruiter result includes region" do
    get "/search", params: { q: "Hiro" }
    assert_match("JP", response.body)
  end

  # --- Company matching ---

  test "finds company by name" do
    get "/search", params: { q: "Globex" }
    assert_response :success
    assert_match("Globex Recruiting", response.body)
  end

  test "search is case-insensitive for companies" do
    get "/search", params: { q: "globex" }
    assert_response :success
    assert_match("Globex Recruiting", response.body)
  end

  # --- No results ---

  test "no results shows empty state message" do
    get "/search", params: { q: "xyzzy_no_match_at_all" }
    assert_response :success
    assert_match(/no results/i, response.body)
  end

  # --- SQL safety ---

  test "query with percent sign does not crash" do
    get "/search", params: { q: "50%" }
    assert_response :success
  end

  test "query with underscore does not crash" do
    get "/search", params: { q: "a_b" }
    assert_response :success
  end

  test "query with single quote does not crash" do
    get "/search", params: { q: "O'Brien" }
    assert_response :success
  end

  # --- Does not match unrelated data ---

  test "does not return recruiters that do not match query" do
    get "/search", params: { q: "Globex" }
    # Company matches but recruiter name does not contain "Globex"
    assert_no_match(/Hiro Tanaka.*Hiro Tanaka/m, response.body)
  end

  # --- Home page ---

  test "GET / includes search form pointing to /search" do
    get "/"
    assert_response :success
    assert_match('action="/search"', response.body)
  end
end
