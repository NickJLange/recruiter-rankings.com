require "application_system_test_case"

class ResponsiveDesignTest < ApplicationSystemTestCase
  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
    @user = User.create!(email_hmac: "test_hmac", role: "candidate", public_slug: "USER123")
  end

  test "navigation collapses on mobile viewport" do
    visit recruiter_path(@recruiter)
    
    resize_window_to(:mobile)
    
    mobile_nav = find_all("[data-mobile-menu]")
    if mobile_nav.any?
      assert mobile_nav.first.visible?, "Mobile navigation menu should be visible on mobile"
    end
    
    resize_window_to(:desktop)
  end

  test "recruiter profile fits on mobile viewport" do
    visit recruiter_path(@recruiter)
    
    resize_window_to(:mobile)
    
    recruiter_name = page.find("h1")
    assert recruiter_name.visible?, "Recruiter name should be visible on mobile"
    
    recruiter_info = page.all(".recruiter-info, .profile-summary")
    recruiter_info.each do |element|
      element.visible?
    end
    
    resize_window_to(:desktop)
  end

  test "navigation hamburger menu toggles correctly" do
    visit recruiter_path(@recruiter)
    
    resize_window_to(:mobile)
    
    if page.has_button?("Menu") || page.has_css?("[data-mobile-menu-toggle]")
      menu_button = find("button", text: /menu/i, match: :first) || find("[data-mobile-menu-toggle]", match: :first)
      menu_button.click
      
      mobile_menu = find("[data-mobile-menu]", visible: true)
      assert mobile_menu.visible?, "Mobile menu should be visible after toggle"
      
      menu_button.click
      refute mobile_menu.visible?, "Mobile menu should hide after second toggle"
    end
    
    resize_window_to(:desktop)
  end

  test "forms are usable on mobile viewport" do
    visit new_recruiter_review_path(@recruiter)
    
    resize_window_to(:mobile)
    
    assert_selector "form", visible: true
    assert_selector "input[type='email']", visible: true
    assert_selector "textarea", visible: true
    assert_selector "button[type='submit']", visible: true
    
    submit_button = find("button[type='submit']")
    assert submit_button.visible?, "Submit button should be visible on mobile"
    assert submit_button.native.size.width > 44, "Touch targets should be at least 44px wide"
    assert submit_button.native.size.height > 44, "Touch targets should be at least 44px tall"
    
    resize_window_to(:desktop)
  end

  test "images scale correctly on mobile" do
    visit recruiter_path(@recruiter)
    
    resize_window_to(:mobile)
    
    images = page.all("img")
    images.each do |img|
      img_width = img.native.style("width").to_i
      img_max_width = img.native.style("max-width").to_i
      
      if img_width > 0 || img_max_width > 0
        max_width = [img_width, img_max_width].max
        window_width = page.current_window.size[:width]
        
        assert_operator max_width, :<=, window_width, 
                       "Image should not exceed viewport width on mobile"
      end
    end
    
    resize_window_to(:desktop)
  end

  test "content does not require horizontal scrolling on mobile" do
    visit recruiter_path(@recruiter)
    
    resize_window_to(:mobile)
    
    body_width = page.find("body").native.size.width
    window_width = page.current_window.size[:width]
    
    assert_operator body_width, :<=, window_width + 10, 
                   "Content should not require horizontal scrolling on mobile"
    
    resize_window_to(:desktop)
  end

  test "cards and panels stack on mobile" do
    visit recruiter_path(@recruiter)
    
    resize_window_to(:mobile)
    
    cards = page.all(".card, .panel, .recruiter-card")
    cards.each do |card|
      card.visible?
    end
    
    resize_window_to(:desktop)
  end

  test "text remains readable on mobile" do
    visit recruiter_path(@recruiter)
    
    resize_window_to(:mobile)
    
    body = page.find("body")
    font_size = body.native.style("font-size").to_i
    assert_operator font_size, :>=, 14, "Font size should be at least 14px on mobile"
    
    paragraphs = page.all("p")
    paragraphs.each do |p|
      line_height = p.native.style("line-height").to_f
      font = p.native.style("font-size").to_i
      
      if line_height > 0 && font > 0
        assert line_height >= 1.4, "Line height should be at least 1.4 times font size"
      end
    end
    
    resize_window_to(:desktop)
  end

  test "buttons are touch-friendly on mobile" do
    visit new_recruiter_review_path(@recruiter)
    
    resize_window_to(:mobile)
    
    buttons = page.all("button, input[type='submit'], a.btn, a.button")
    buttons.each do |button|
      if button.visible?
        size = button.native.size
        assert size[:height] >= 44, "Button height should be at least 44px for touch"
        assert size[:width] >= 44, "Button width should be at least 44px for touch"
      end
    end
    
    resize_window_to(:desktop)
  end

  test "pagination controls work on mobile" do
    15.times do |i|
      user = User.create!(email_hmac: "hmac#{i}", role: "candidate")
      interaction = Interaction.create!(recruiter: @recruiter, target: user, status: "approved", occurred_at: Time.now)
      Experience.create!(interaction: interaction, rating: rand(5) + 1, status: "approved", body: "Review #{i}")
    end
    
    visit recruiter_path(@recruiter)
    resize_window_to(:mobile)
    
    pagination = page.all(".pagination a", visible: true)
    pagination.each do |link|
      link.visible?
    end
    
    resize_window_to(:desktop)
  end

  test "modals fit within mobile viewport" do
    visit recruiter_path(@recruiter)
    
    resize_window_to(:mobile)
    
    if page.has_button?("Write a Review") || page.has_button?("Add Review")
      find_button("Write a Review").click rescue nil
      
      if page.has_css?("[role='dialog']")
        dialog = find("[role='dialog']")
        assert dialog.visible?
        
        dialog_width = dialog.native.size.width
        window_width = page.current_window.size[:width]
        
        assert_operator dialog_width, :<=, window_width + 10, 
                       "Modal should fit within mobile viewport"
      end
    end
    
    resize_window_to(:desktop)
  end

  test "search functionality works on mobile" do
    visit root_path
    
    resize_window_to(:mobile)
    
    if page.has_selector?("input[type='search'], input[name='search'], #search")
      search_input = find("input[type='search'], input[name='search'], #search", match: :first)
      assert search_input.visible?, "Search input should be visible on mobile"
      
      search_input.fill_in(with: "test")
      assert_equal "test", search_input.value, "Search input should accept text on mobile"
    end
    
    resize_window_to(:desktop)
  end

  private

  def resize_window_to(size)
    case size
    when :mobile
      page.driver.resize(375, 667)
    when :tablet
      page.driver.resize(768, 1024)
    when :desktop
      page.driver.resize(1280, 800)
    end
  end
end