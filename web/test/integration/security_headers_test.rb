require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "Content-Security-Policy header is present and uses nonces" do
    get "/"
    assert_response :success

    # Check for CSP header
    csp = response.headers["Content-Security-Policy"]
    assert_not_nil csp, "Content-Security-Policy header should be present"

    # Check for nonce usage in script-src
    assert_match /script-src 'self' https: 'strict-dynamic' 'nonce-[a-zA-Z0-9+\/=]+'/, csp, "CSP should include script-src with strict-dynamic and nonce"

    # Check that inline scripts have the nonce attribute
    # We need to extract the nonce from the header to check the body
    nonce_match = csp.match(/'nonce-([a-zA-Z0-9+\/=]+)'/)
    assert nonce_match, "Could not extract nonce from CSP header"
    nonce = nonce_match[1]

    # Verify script tags in body have the correct nonce
    assert_match /<script nonce="#{Regexp.escape(nonce)}">/, response.body, "Inline scripts should use the generated nonce"
  end
end
