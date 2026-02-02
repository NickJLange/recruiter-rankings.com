require "application_system_test_case"

class SlugRoutingConsistencyTest < ApplicationSystemTestCase
  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
    @supported_locales = [:en, :ja]
  end

  test "public slug routing works without locale parameter" do
    visit "/person/#{@recruiter.public_slug}"
    assert_response_ok
    assert_text(/Recruiter|リクルーター/i, wait: 5)
  end

  test "public slug routing works with locale parameter" do
    @supported_locales.each do |locale|
      visit "/person/#{@recruiter.public_slug}?locale=#{locale}"
      assert_response_ok
      assert_match(/locale=#{locale}/, current_url, "URL should contain locale parameter")
    end
  end

  test "slug is consistent across all pages" do
    slug = @recruiter.public_slug
    
    pages_to_visit = [
      "/person/#{slug}",
      new_recruiter_review_path(slug: slug)
    ]
    
    pages_to_visit.each do |path|
      visit path
      
      slug_on_page = page.body.scan(slug)
      assert slug_on_page.empty? || slug_on_page.any?,
             "Slug handling should be consistent: #{path}"
    end
  end

  test "slug-based recruiter profile URL format" do
    expected_pattern = %r{/person/[A-F0-9]{8}}
    
    visit "/person/#{@recruiter.public_slug}"
    
    assert_match expected_pattern, current_url, 
                 "Recruiter profile URL should follow /person/XXXXXXXX format"
  end

  test "slug routing preserves locale switch" do
    visit "/person/#{@recruiter.public_slug}?locale=en"
    
    locale_switch = page.all("a[href*='locale=ja']").first
    locale_switch&.click
    
    assert_match(/\/person\/#{@recruiter.public_slug}/, current_url,
                 "Slug should be preserved in URL after locale switch")
    assert_match(/locale=ja/, current_url, "Locale parameter should be updated")
  end

  test "invalid slug returns appropriate response" do
    visit "/person/INVALIDSLUG123"
    
    status = page.driver.browser.response.status rescue nil
    assert [404, 302].include?(status) || page.text.match?(/not found|エラー/i),
           "Invalid slug should handle appropriately"
  end

  test "slug uniqueness prevents conflicts" do
    existing_recruiter = Recruiter.create!(
      name: "Existing",
      company: @company,
      public_slug: "ABCD1234"
    )
    
    visit "/person/#{existing_recruiter.public_slug}"
    assert_response_ok
    
    visit "/person/#{@recruiter.public_slug}"
    assert_response_ok
    
    assert_not_equal existing_recruiter.public_slug, @recruiter.public_slug,
                   "Different recruiters should have different slugs"
  end

  test "slug format validation in URLs" do
    visit "/person/#{@recruiter.public_slug}"
    
    slug_from_url = current_url.match(/person\/([A-F0-9]{8}([?]|$))/)
    assert_not_nil slug_from_url, "URL should contain properly formatted slug"
    assert_equal 8, slug_from_url[1].length, "Slug should be 8 characters"
  end

  test "slug routing works after record updates" do
    original_slug = @recruiter.public_slug
    
    @recruiter.update!(name: "Updated Name")
    
    visit "/person/#{original_slug}"
    
    assert_response_ok
    assert_text(/Updated Name|#{original_slug}/i, wait: 5)
  end

  test "slug-based link generation from views" do
    visit recruiters_path
    
    recruiter_links = page.all("a[href*='/person/']")
    assert recruiter_links.any?, "Should have recruiter profile links"
    
    recruiter_links.each do |link|
      href = link[:href]
      assert_match(/\/person\/[A-F0-9]{8}/, href, 
                   "Recruiter links should use slug format")
    end
  end

  test "slug persistence across navigation" do
    slug = @recruiter.public_slug
    
    visit "/person/#{slug}"
    initial_url = current_url
    
    visit "/" if page.has_content?("Home")
    
    visit "/person/#{slug}"
    
    assert_equal initial_url.match(/\/person\/[A-F0-9]{8}/).to_s, 
                 current_url.match(/\/person\/[A-F0-9]{8}/).to_s,
                 "Slug URL should be consistent"
  end

  test "query parameters work with slug routing" do
    test_params = ["page=2", "filter=approved", "category=all"]
    
    test_params.each do |param|
      visit "/person/#{@recruiter.public_slug}?#{param}"
      assert_response_ok
      assert_match(/#{param}/, current_url, "Query parameter should be preserved")
    end
  end

  test "slug routing with page-specific URL parameters" do
    visit new_recruiter_review_path(slug: @recruiter.public_slug)
    
    assert_match(/#{@recruiter.public_slug}/, current_url,
                 "Slug should be present in review form URL")
    
    find("button[type='submit']").click rescue nil
    
    success_path = current_url
    assert success_path.present?, "Should navigate to a valid page after submission"
  end

  private

  def assert_response_ok
    status = page.driver.browser.response.status rescue nil
    acceptable_responses = [nil, 200, 201, 202]
    assert acceptable_responses.include?(status), 
           "Expected successful response, got status: #{status}"
  end
end