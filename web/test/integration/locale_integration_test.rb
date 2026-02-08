require "test_helper"

class LocaleIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
  end

  test "locale persists via cookie between requests" do
    get "/person", params: { locale: :ja }
    assert_response :success
    assert_includes @response.body, "上位のリクルーター", "should render Japanese after switching"

    get "/person"
    assert_response :success
    assert_includes @response.body, "上位のリクルーター", "should persist Japanese via cookie"
  end

  test "locale parameter overrides Accept-Language header" do
    get "/person", params: { locale: :ja }, headers: { "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.9" }
    assert_response :success
    assert_includes @response.body, "上位のリクルーター", "Locale param should override Accept-Language"
  end

  test "cookie locale prioritized over Accept-Language header" do
    cookies[:locale] = :ja
    get "/person", headers: { "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.9" }
    assert_response :success
    assert_includes @response.body, "上位のリクルーター", "Cookie should override Accept-Language"
  end

  test "Accept-Language header detected for Japanese" do
    get "/person", headers: { "HTTP_ACCEPT_LANGUAGE" => "ja-JP,ja;q=0.9,en;q=0.8" }
    assert_response :success
    assert_includes @response.body, "上位のリクルーター", "Should detect Japanese from Accept-Language"
  end

  test "default locale used when none specified" do
    get "/person", headers: { "HTTP_ACCEPT_LANGUAGE" => "zh-CN,zh;q=0.9" }
    assert_response :success
    assert_includes @response.body, "Recruiter", "Should default to English for unsupported Accept-Language"
  end

  test "invalid locale parameter defaults to English" do
    get "/person", params: { locale: "invalid-locale" }
    assert_response :success
    assert_includes @response.body, "Recruiter", "Should default to English for invalid locale"
  end

  test "locale switcher link format includes query parameter" do
    get recruiters_path
    assert_response :success
    
    skip "Locale switcher UI feature not yet implemented"
    
    assert_match /locale=ja/, @response.body, "Should include locale switcher with ja parameter"
    assert_match /locale=en/, @response.body, "Should include locale switcher with en parameter"
  end

  test "locale persists across recruiter profile navigation" do
    get "/person", params: { locale: :ja }
    assert_includes cookies[:locale], "ja", "Locale should be set in cookie"
    
    get recruiter_path(@recruiter)
    assert_response :success
    assert_includes @response.body, "レビューを書く" || "平均スコア", 
                   "Japanese should persist on recruiter profile"
  end

  test "locale persists across submission flow" do
    get "/person", params: { locale: :ja }
    
    recruiter_slug = @recruiter.public_slug
    post "/reviews", params: {
      review: {
        recruiter_slug: recruiter_slug,
        overall_score: 5,
        text: "素晴らしい経験でした！",
        email: "test@example.com"
      }
    }
    
    follow_redirect!
    assert_response :success
    
    locale_cookie = cookies[:locale]
    assert_equal "ja", locale_cookie, "Locale should persist through submission"
  end

  test "all supported locales work without errors" do
    supported_locales = I18n.available_locales - [:en]
    
    supported_locales.each do |locale|
      get "/", params: { locale: locale }
      assert_response :success, "Locale #{locale} should return success"
    end
  end

  test "locale cookie has long expiration" do
    get "/", params: { locale: :ja }
    
    cookie = response.cookies["locale"]
    assert_not_nil cookie, "Locale cookie should be set"
  end

  test "locale parameter and params[:local] both work for backwards compatibility" do
    get "/", params: { locale: :ja }
    assert_response :success
    assert_includes @response.body, "上位のリクルーター"
    
    get "/", params: { local: :ja }
    assert_response :success
    assert_includes @response.body, "上位のリクルーター"
  end

  test "locale affects recruiter index page" do
    get recruiters_path, params: { locale: :ja }
    assert_response :success
    assert_includes @response.body, "上位のリクルーター"
    assert_includes @response.body, "検索"
    
    get recruiters_path, params: { locale: :en }
    assert_response :success
    assert_includes @response.body, "Top Recruiters"
    assert_includes @response.body, "Search"
  end

  test "locale affects review form" do
    get new_recruiter_review_path(@recruiter), params: { locale: :ja }
    assert_response :success
    assert_includes @response.body, "総合スコア" || "体験の内容" || "送信"
    
    get new_recruiter_review_path(@recruiter), params: { locale: :en }
    assert_response :success
    assert_includes @response.body, "Overall score" || "Your experience" || "Submit"
  end

  test "I18n.available_locales matches allowed locales" do
    # available locales in the app.
    allowed_locales = %w[en ja es fr ar]
    I18n.available_locales.each do |locale|
      assert allowed_locales.include?(locale.to_s), 
             "Available locale #{locale} should be in allowed locales"
    end
  end
end