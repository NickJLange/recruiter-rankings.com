require "application_system_test_case"

class SearchSystemTest < ApplicationSystemTestCase
  setup do
    @company   = Company.create!(name: "Globex Recruiting", region: "US")
    @recruiter = Recruiter.create!(name: "Hiro Tanaka", company: @company,
                                   public_slug: "hiro-tanaka-sys", region: "JP")
  end

  test "search page loads with empty state" do
    visit "/search"
    assert_selector "input[type='search']"
    assert_text "at least 2 characters"
  end

  test "searching from /search finds a recruiter" do
    visit "/search"
    fill_in placeholder: /recruiter/i, with: "Hiro"
    click_button "Search"
    assert_text "Hiro Tanaka"
    assert_text "Globex Recruiting"
  end

  test "searching from /search finds a company" do
    visit "/search"
    fill_in placeholder: /recruiter/i, with: "Globex"
    click_button "Search"
    assert_text "Globex Recruiting"
  end

  test "no-match query shows empty state" do
    visit "/search"
    fill_in placeholder: /recruiter/i, with: "xyzzy_no_match"
    click_button "Search"
    assert_text /no results/i
  end

  test "home page has a working search bar" do
    visit "/"
    assert_selector "input[type='search']"
    fill_in placeholder: /recruiter/i, with: "Hiro"
    find("input[type='submit']").click
    assert_current_path "/search", ignore_query: true
    assert_text "Hiro Tanaka"
  end

  test "search result links to recruiter profile" do
    visit "/search?q=Hiro"
    assert_selector "a", text: "Hiro Tanaka"
    click_link "Hiro Tanaka"
    assert_current_path recruiter_path(@recruiter.public_slug)
  end

  test "search result links to company page" do
    visit "/search?q=Globex"
    assert_selector "a", text: "Globex Recruiting"
    click_link "Globex Recruiting"
    assert_current_path company_path(@company)
  end
end
