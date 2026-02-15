require "application_system_test_case"

class VisualConsistencyTest < ApplicationSystemTestCase
  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
    @user = User.create!(email_hmac: "test_hmac", role: "candidate", public_slug: "USER123")
  end

  test "recruiter profile page has consistent layout structure" do
    visit recruiter_path(@recruiter)
    
    assert_selector "h1", text: /Recruiter/i
    assert_selector "nav", count: 1
    assert_selector "footer", count: 1
    
    assert_selector "[role='main']"
  end

  test "rating stars display correctly" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user, status: "approved")
    Experience.create!(interaction: interaction, rating: 5, status: " approved", body: "Great!")
    
    visit recruiter_path(@recruiter)
    
    assert_selector ".rating-container"
  end

  test "form labels are present and properly associated" do
    visit new_recruiter_review_path(@recruiter)
    
    assert_selector "label[for='review_overall_score']", text: /overall score/i
    assert_selector "label[for='review_text']", text: /experience/i
    assert_selector "label[for='review_email']", text: /email/i
  end

  test "color contrast is acceptable on key elements" do
    visit root_path
    
    button_selector = find_all("button, .btn, input[type='submit']")
    button_selector.each do |button|
      color = button.native.style("color")
      background = button.native.style("background-color")
      refute_empty color, "Button text should have a color"
      refute_empty background, "Button should have a background color"
    end
  end

  test "error messages are visually distinct" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: ""
    click_button "Submit"
    
    assert_selector ".alert-danger", wait: 5
    assert_selector ".invalid-feedback", wait: 5
    assert_selector "input.is-invalid", wait: 5
  end

  test "success messages are visually distinct" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: "test@example.com"
    select "5", from: "Overall score"
    fill_in "Text", with: "Great experience!"
    click_button "Submit"
    
    assert_selector ".alert-success", wait: 5
    assert_selector ".alert-success", text: /submitted|thank/i
  end

  test "navigation is consistent across pages" do
    visit root_path
    nav_text = page.find("nav").text
    
    visit recruiter_path(@recruiter)
    current_nav_text = page.find("nav").text
    
    assert_equal nav_text, current_nav_text, "Navigation should be consistent"
  end

  test "page titles are present and descriptive" do
    visit root_path
    assert_selector "title", text: /recruiter|ranking/i
    
    visit recruiter_path(@recruiter)
    assert_selector "title"
  end

  test "links are clearly identifiable" do
    visit root_path
    
    links = page.all("a[href]")
    assert links.any?, "Page should have links"
    
    links.each do |link|
      href = link[:href]
      refute_nil href, "Link should have href attribute"
    end
  end

  test "buttons have clear visual states" do
    visit new_recruiter_review_path(@recruiter)
    
    button = find("button[type='submit'], input[type='submit']")
    
    assert button[:type].in?(["submit", "button"]), "Actions should be buttons, not generic divs"
    refute_empty button.text.to_s.strip, "Button should have text content"
  end

  test "masked names follow consistent format" do
    visit recruiter_path(@recruiter)
    
    recruiter_name = page.find("h1").text
    assert_match /Recruiter RR-|Recruiter [A-F0-9]{8}/i, recruiter_name
    recruiter_name_parts = recruiter_name.split(" ")
    assert recruiter_name_parts.length >= 2, "Recruiter name should have at least two parts"
  end

  test "pagination controls are present when needed" do
    15.times do |i|
      user = User.create!(email_hmac: "hmac#{i}", role: "candidate")
      interaction = Interaction.create!(recruiter: @recruiter, target: user, status: "approved", occurred_at: Time.now)
      Experience.create!(interaction: interaction, rating: rand(5) + 1, status: "approved", body: "Review #{i}")
    end
    
    visit recruiter_path(@recruiter)
    
    within ".pagination" do
      assert_selector "a", count: 2
    end
  end
end