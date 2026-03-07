require "application_system_test_case"

# Smoke tests for Clerk auth guards and key nav flows.
# Uses headless Chrome (Cuprite) with FakeClerkMiddleware for session injection.
# Note: root_path (/) serves the Jekyll static marketing page — Rails app is at /person.
class ClerkAuthSmokeTest < ApplicationSystemTestCase
  setup do
    @company = Company.create!(name: "Umbrella Corp", region: "US")
    @recruiter = Recruiter.create!(name: "Albert Wesker", company: @company, public_slug: "albert-wesker-1")
  end

  test "recruiter listing loads without auth" do
    visit recruiters_path
    assert_selector "header"
    assert_selector "a", text: "Submit Review"
  end

  test "submit review nav button goes to review landing page prompting sign-in" do
    visit recruiters_path
    click_link "Submit Review"
    assert_current_path "/reviews/new"
    assert_text "Sign in to continue"
  end

  test "admin requires authentication — redirected when not signed in" do
    visit "/admin"
    assert_no_text "Admin Dashboard"
  end

  test "admin is accessible when signed in with full admin credentials" do
    sign_in_as_clerk(role: :admin, providers: [:email, :linkedin, :github], two_factor: true)
    visit "/admin"
    assert_text "Admin Dashboard"
  end

  test "review form requires authentication — redirected when not signed in" do
    visit "/person/#{@recruiter.public_slug}/reviews/new"
    assert_no_text "Share Your Experience"
  end

  test "review form is accessible when signed in as candidate" do
    sign_in_as_clerk(role: :candidate, providers: [:email])
    visit "/person/#{@recruiter.public_slug}/reviews/new"
    assert_selector "form"
  end
end
