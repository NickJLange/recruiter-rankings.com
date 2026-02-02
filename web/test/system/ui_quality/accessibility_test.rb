require "application_system_test_case"

class AccessibilityTest < ApplicationSystemTestCase
  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
    @user = User.create!(email_hmac: "test_hmac", role: "candidate", public_slug: "USER123")
  end

  test "form inputs have accessible labels" do
    visit new_recruiter_review_path(@recruiter)
    
    assert_selector "input[id='review_overall_score'][aria-label*='rating']"
    assert_selector "textarea[id='review_text'][aria-label*='experience']"
    assert_selector "input[id='review_email'][aria-label*='email']"
  end

  test "form errors have aria-live regions" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: ""
    click_button "Submit"
    
    assert_selector "[role='alert']"
    assert_selector "[aria-live='polite']"
  end

  test "success messages use aria-live" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: "test@example.com"
    select "5", from: "Overall score"
    fill_in "Text", with: "Great experience!"
    click_button "Submit"
    
    assert_selector ".alert-success[role='alert']"
    assert_selector ".alert-success[aria-live='polite']"
  end

  test "navigation has semantic HTML structure" do
    visit root_path
    
    assert_selector "nav", visible: true
    assert_selector "main", visible: true
    assert_selector "footer", visible: true
    
    nav = page.find("nav")
    assert nav[:role].in?([nil, "navigation"]), "Nav should have navigation role"
  end

  test "buttons and links have focus indicators" do
    visit new_recruiter_review_path(@recruiter)
    
    button = find("button[type='submit']")
    button.native.send_keys(:Tab)
    
    assert_equal button, page.active_element, "Button should receive focus"
  end

  test "images have alt text" do
    screenshots = Recruiter.create!(name: "Test Recruiter", company: @company)
    visit recruiter_path(screenshots)
    
    images = page.all("img")
    images.each do |img|
      alt = img[:alt]
      refute_nil alt, "Image should have alt attribute"
      refute_empty alt.to_s.strip, "Alt text should not be empty unless decorative"
    end
  end

  test "headings are in correct hierarchical order" do
    visit root_path
    
    headings = page.all("h1, h2, h3, h4, h5, h6")
    last_level = 0
    
    headings.each do |heading|
      level = heading.tag_name.match(/\d/).to_s.to_i
      assert_operator level, :<=, last_level + 1, 
                     "Heading levels should not skip (found h#{level} after h#{last_level})"
      last_level = level
    end
  end

  test "rating inputs are keyboard accessible" do
    visit new_recruiter_review_path(@recruiter)
    
    rating_input = find("#review_overall_score")
    rating_input.native.send_keys(:Tab)
    rating_input.native.send_keys("5")
    
    assert_equal "5", rating_input.value, "Rating input should accept keyboard input"
  end

  test "skip links present for keyboard users" do
    visit root_path
    
    body_html = page.body
    assert body_html.include?("Skip to") || body_html.include?("skip-link"), 
           "Page should include skip navigation links"
  end

  test "modal dialogs have proper accessibility attributes" do
    visit recruiter_path(@recruiter)
    find_button("Write a Review").click if page.has_button?("Write a Review")
    
    if page.has_css?("[role='dialog']")
      dialog = find("[role='dialog']")
      assert dialog[:"aria-modal"], "Dialog should have aria-modal attribute"
      assert dialog[:"aria-labelledby"], "Dialog should reference-labelledby"
    end
  end

  test "form fields have required attributes marked" do
    visit new_recruiter_review_path(@recruiter)
    
    required_fields = find_all("[required]")
    assert required_fields.any?, "Form should have required fields"
    
    required_fields.each do |field|
      assert field[:required], "Field should be marked as required"
    end
  end

  test "color is not the only indicator of information" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: ""
    click_button "Submit"
    
    error_fields = find_all(".is-invalid, .error, [aria-invalid='true']")
    assert error_fields.any?, "Invalid fields should be marked beyond just color"
  end

  test "page has appropriate language attribute" do
    visit root_path
    
    html_tag = find("html")
    assert html_tag[:lang], "HTML tag should have lang attribute"
  end

  test "forms have proper submit indication" do
    visit new_recruiter_review_path(@recruiter)
    
    button = find("button[type='submit'], input[type='submit']")
    refute_empty button.text.to_s.strip, "Submit button should have descriptive text"
    assert button.text.match(/submit|save|send|continue/i).present?, 
           "Submit button should indicate submit action"
  end
end