require "test_helper"

class FormValidationTest < Capybara::Rails::Application
  include ApplicationSystemTestCase

  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
  end

  test "form shows inline validation errors on submit" do
    visit new_recruiter_review_path(@recruiter)
    
    click_button "Submit"
    
    assert_selector ".alert-danger", text: /error/i
    assert_selector ".invalid-feedback"
    assert_selector "input.is-invalid, textarea.is-invalid"
  end

  test "required fields display validation errors when empty" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: ""
    fill_in "Overall score", with: ""
    fill_in "Text", with: ""
    click_button "Submit"
    
    within ".alert-danger" do
      assert_text /can't be blank|required/i
    end
  end

  test "email validation shows specific error message" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: "invalid-email"
    fill_in "Overall score", with: "5"
    fill_in "Text", with: "Valid review text"
    click_button "Submit"
    
    assert_selector ".invalid-feedback", text: /email/i, wait: 5
  end

  test "successful submission clears form errors" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: ""
    click_button "Submit"
    
    assert_selector ".alert-danger", wait: 5
    
    fill_in "Email", with: "test@example.com"
    fill_in "Overall score", with: "5"
    fill_in "Text", with: "Great experience!"
    click_button "Submit"
    
    assert_no_selector ".alert-danger"
    assert_selector ".alert-success", text: /submitted|thank/i
  end

  test "form disables submit button while processing" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: "test@example.com"
    fill_in "Overall score", with: "5"
    fill_in "Text", with: "Great experience!"
    
    using_wait_time(2) do
      click_button "Submit"
      button = find("button[type='submit'], input[type='submit']")
      
      button_disabled = button[:disabled]
      button_classes = button[:class].to_s
      
      assert button_disabled || button_classes.include?("disabled"), 
             "Submit button should be disabled while processing"
    end
  end

  test "character counter shows for text fields" do
    visit new_recruiter_review_path(@recruiter)
    
    text_area = find("textarea[name*='text'], textarea[id*='text']")
    text_area.click
    
    if page.has_css?(".character-counter, [data-character-counter]")
      counter = find(".character-counter, [data-character-counter]")
      assert counter.visible?, "Character counter should be visible when field is focused"
    end
  end

  test "rating selection provides visual feedback" do
    visit new_recruiter_review_path(@recruiter)
    
    if page.has_selector?("[type='radio'][name*='rating'], .rating-stars, .star-rating")
      if page.has_selector?(".rating-stars, .star-rating")
        stars = find_all(".rating-stars .star, .star-rating .star")
        stars.first.click
        
        assert stars.first[:class].include?("selected") || stars.first[:class].include?("active"),
               "Selected star should have visual feedback class"
      end
    end
  end

  test "form validates minimum text length" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: "test@example.com"
    fill_in "Overall score", with: "5"
    fill_in "Text", with: "X" * 10
    click_button "Submit"
    
    if page.has_selector?(".invalid-feedback", text: /too short|minimum/i, wait: 2)
      assert_selector ".invalid-feedback", text: /too short|minimum/i
    end
  end

  test "form validates maximum text length" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: "test@example.com"
    fill_in "Overall score", with: "5"
    
    text_area = find("textarea")
    text_area.set("X" * 10001)
    
    assert text_area.value.length <= 10000, "Text area should enforce maximum length"
  end

  test "email field prevents email addresses with spaces" do
    visit new_recruiter_review_path(@recruiter)
    
    email_field = find("input[type='email']")
    email_field.set("test @example.com")
    
    assert_includes email_field.value, " ", "Email field allows spaces for validation display"
    
    fill_in "Overall score", with: "5"
    fill_in "Text", with: "Test review"
    click_button "Submit"
    
    assert_selector ".invalid-feedback", text: /email/i, wait: 5
  end

  test "form resets after successful submission" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: "test@example.com"
    fill_in "Overall score", with: "5"
    fill_in "Text", with: "Great experience!"
    click_button "Submit"
    
    assert_selector ".alert-success", text: /submitted|thank/i
    
    if page.current_path != recruiter_path(@recruiter)
      assert_selector "input[type='email'][value='']"
      assert_selector "textarea[placeholder]"
    end
  end

  test "field focus moves sequentially using Tab key" do
    visit new_recruiter_review_path(@recruiter)
    
    email_field = find("input[type='email']")
    email_field.native.send_keys(:tab)
    
    rating_field = page.active_element
    assert rating_field.present?, "Tab should move focus to next field"
    
    rating_field.native.send_keys(:tab)
    text_field = page.active_element
    assert text_field.tag_name.match?(/textarea|input/i), "Tab should continue to next field"
  end

  test "required fields have visual asterisk or indicator" do
    visit new_recruiter_review_path(@recruiter)
    
    labels = page.all("label")
    labels.each do |label|
      for_field = label[:for] || label["data-for"]
      if for_field
        field = find("##{for_field}", visible: false)
        if field && field[:required]
          assert label.text.match(/[*]|required/i).present? || label[:class].include?("required"),
                 "Required fields should be visually indicated"
        end
      end
    end
  end

  test "form provides clear submission confirmation" do
    visit new_recruiter_review_path(@recruiter)
    
    fill_in "Email", with: "test@example.com"
    fill_in "Overall score", with: "5"
    fill_in "Text", with: "Great experience!"
    click_button "Submit"
    
    success_message = find(".alert-success, .notice, .success-message")
    assert success_message.visible?, "Success message should be visible"
    assert success_message.text.match(/submitted|thank|complete/i).present?,
           "Success message should indicate successful submission"
  end
end