require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "generate_email_hmac uses default pepper in test" do
    email = "test@example.com"
    # This calls the method we are about to create.
    # Since we haven't created it yet, this test will fail if run now (undefined method).
    # But that's TDD.

    # We verify that it matches the expected HMAC using the default pepper
    pepper = "demo-only-pepper-not-secret"
    expected = OpenSSL::HMAC.hexdigest("SHA256", pepper, email)

    assert_equal expected, User.generate_email_hmac(email)
  end

  test "generate_email_hmac raises in production without pepper" do
    # Stub Rails.env.production? to return true
    Rails.stub :env, ActiveSupport::StringInquirer.new("production") do
      # Ensure ENV is nil for the pepper
      original_pepper = ENV["SUBMISSION_EMAIL_HMAC_PEPPER"]
      ENV["SUBMISSION_EMAIL_HMAC_PEPPER"] = nil

      begin
        assert_raises(RuntimeError) do
          User.generate_email_hmac("test@example.com")
        end
      ensure
        ENV["SUBMISSION_EMAIL_HMAC_PEPPER"] = original_pepper
      end
    end
  end
end
