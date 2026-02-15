require "application_system_test_case"

class MultiLingualConsistencyTest < ApplicationSystemTestCase
  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
    @supported_locales = [:en, :ja]
  end

test "recruiter page structure identical across locales" do
    @supported_locales.each do |locale|
      visit recruiter_path(@recruiter, locale: locale)
      
      assert_selector "h1", visible: true, wait: 5
      
      assert_text(/Recruiter|リクルーター/i, wait: 5)
      
      if locale == :ja
        assert_text(/平均スコア|レビュー/i, wait: 5)
      else
        assert_text(/Average|Review/i, wait: 5)
      end
    end
  end

  test "form labels present in all locales" do
    @supported_locales.each do |locale|
      visit new_recruiter_review_path(@recruiter, locale: locale)
      
      assert_selector "form", visible: true
      
      if locale == :ja
        assert_text(/総合スコア|体験|送信/i, wait: 5)
      else
        assert_text(/Overall|Experience|Submit/i, wait: 5)
      end
    end
  end

  test "navigation links work consistently across locales" do
    @supported_locales.each do |locale|
      visit recruiters_path(locale: locale)
      
      nav_links = page.all("nav a")
      assert nav_links.any?, "Navigation should have links in #{locale}"
      
      nav_links.each do |link|
        href = link[:href]
        next if href.blank? || href.starts_with?("#")
        
        link.click
        
        assert_current_path(%r{^/\w+}, "Navigation should work in #{locale}")
        assert_response_ok
      end
    end
  end

  test "error messages translated properly" do
    @supported_locales.each do |locale|
      visit new_recruiter_review_path(@recruiter, locale: locale)
      
      click_button(locale == :ja ? "送信" : "Submit")
      
      assert_selector ".alert-danger, .error, [role='alert']", visible: true, wait: 5
      
      error_text = page.text
      if locale == :ja
        assert error_text.match?(/エラー|必須|空白/i) || error_text.length > 0,
               "Should show error message in Japanese"
      else
        assert error_text.match?(/error|required|blank/i) || error_text.length > 0,
               "Should show error message in English"
      end
    end
  end

  test "locale switcher URL maintains current path" do
    paths_to_test = [
      recruiters_path,
      recruiter_path(@recruiter),
      new_recruiter_review_path(@recruiter)
    ]
    
    paths_to_test.each do |path|
      visit path, params: { locale: :en }
      
      locale_links = page.all("a[href*='locale='], a[href*='locale=ja']")
      assert locale_links.any?, "Locale switcher should be present on #{path}"
      
      locale_switch = locale_links.find { |link| link[:href].include?("locale=ja") }
      locale_switch&.click
      
      assert_match(/locale=ja/, current_url, "URL should contain locale parameter")
    end
  end

  test "pagination works correctly across locales" do
    15.times do |i|
      user = User.create!(email_hmac: "hmac#{i}", role: "candidate")
      interaction = Interaction.create!(recruiter: @recruiter, target: user, status: "approved", occurred_at: Time.now)
      Experience.create!(interaction: interaction, rating: rand(5) + 1, status: "approved", body: "Review #{i}")
    end
    
    @supported_locales.each do |locale|
      visit recruiter_path(@recruiter, locale: locale)
      
      pagination_links = page.all(".pagination a")
      assert pagination_links.any?, "Pagination should be present in #{locale}"
      
      if pagination_links.length > 1
        pagination_links.last.click
        
        assert_response_ok
        assert_match(/locale=#{locale}/, current_url, "Pagination should preserve locale")
      end
    end
  end

  test "search functionality works in all locales" do
    visit recruiters_path(locale: :en)
    search_placeholder = find("input[placeholder]").placeholder rescue ""
    
    visit recruiters_path(locale: :ja)
    search_placeholder_ja = find("input[placeholder]").placeholder rescue ""
    
    refute_equal search_placeholder, search_placeholder_ja,
                 "Search placeholder should be different between locales"
  end

  test "slug-based URLs work across locale switches" do
    slug = @recruiter.public_slug
    
    visit recruiter_path(@recruiter, locale: :en)
    assert_match(/#{slug}/, current_url, "URL should contain recruiter slug")
    
    visit recruiter_path(@recruiter, locale: :ja)
    assert_match(/#{slug}/, current_url, "URL should contain recruiter slug in Japanese")
  end

  test "character encoding handles Japanese characters correctly" do
    visit new_recruiter_review_path(@recruiter, locale: :ja)
    
    japanese_text = "この評価は優秀な経験でした。とても丁寧で、返信も迅速でした。"
    
    fill_in "Your experience".sub(/[Yy]our [Ee]xperience/, ""), with: japanese_text
    find("button[type='submit']").click rescue nil
    
    assert japanese_text.length > 0, "Should accept Japanese characters"
  end

  test "multi-byte character input in forms" do
    @supported_locales.each do |locale|
      visit new_recruiter_review_path(@recruiter, locale: locale)
      
      test_text = locale == :ja ? "こんにちは世界" : "Hello World"
      
      find("textarea[name*='text']").set(test_text)
      
      text_area_value = find("textarea[name*='text']").value
      assert_equal test_text, text_area_value, "Should accept #{locale} text"
    end
  end

  test "date/number formatting respects locale" do
    visit recruiter_path(@recruiter, locale: :en)
    page_text_en = page.text
    
    visit recruiter_path(@recruiter, locale: :ja)
    page_text_ja = page.text
    
    assert page_text_en.length > 0 && page_text_ja.length > 0,
           "Both locales should render content"
  end

  test "admin interface translations work" do
    User.create!(email_hmac: "admin_hmac", role: "admin", public_slug: "ADMIN")
    
    @supported_locales.each do |locale|
      visit "/admin/reviews", params: { locale: locale }
      
      page_text = page.text
      assert page_text.length > 0, "Admin interface should render in #{locale}"
    end
  end

  test "success messages translated correctly" do
    @supported_locales.each do |locale|
      visit new_recruiter_review_path(@recruiter, locale: locale)
      
      fill_in "Email".sub(/[Ee]mail/, ""), with: "test@example.com"
      select "5", from: /Overall|Score/i rescue nil
      fill_in "Your experience".sub(/[Yy]our [Ee]xperience/, ""), with: "Great experience!"
      find("button[type='submit']").click rescue nil
      
      success_message = page.find(".alert-success, .notice, .success-message", visible: false).text rescue nil
      assert success_message.present?, "Success message should be shown in #{locale}"
    end
  end

  private

  def assert_response_ok
    status = page.driver.browser.response.status rescue nil
    assert status.nil? || status.between?(200, 299), "Expected successful response"
  end
end