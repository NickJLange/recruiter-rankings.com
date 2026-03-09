require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, using: :chrome, screen_size: [1400, 900], options: {
    browser_options: { "no-sandbox" => nil },
    headless: true,
    js_errors: false
  }

  include ClerkTestHelper

  # Override for system tests: store session in class-level store and set a
  # cookie so the server thread can read it on every request from the browser.
  def sign_in_as_clerk(role: :candidate, providers: [:email], two_factor: false, user_id: nil)
    mock = build_clerk_mock(role: role, providers: providers, two_factor: two_factor, user_id: user_id)
    @_system_clerk_key = SecureRandom.hex(16)
    FakeClerkMiddleware.store_session(@_system_clerk_key, mock)
    # Must visit the domain first so the cookie is set on the right host
    visit root_path
    page.driver.set_cookie("_clerk_test_key", @_system_clerk_key)
    mock
  end

  def sign_out_clerk
    FakeClerkMiddleware.clear_session(@_system_clerk_key) if @_system_clerk_key
    @_system_clerk_key = nil
  end
end
