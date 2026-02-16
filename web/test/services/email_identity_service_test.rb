require "test_helper"

class EmailIdentityServiceTest < ActiveSupport::TestCase
  setup do
    @service = EmailIdentityService.new(pepper: "test-pepper")
  end

  test "hmac_email returns consistent hash for same email" do
    hash1 = @service.hmac_email("test@example.com")
    hash2 = @service.hmac_email("test@example.com")
    assert_equal hash1, hash2
  end

  test "hmac_email returns different hashes for different emails" do
    hash1 = @service.hmac_email("alice@example.com")
    hash2 = @service.hmac_email("bob@example.com")
    refute_equal hash1, hash2
  end

  test "hmac_email strips whitespace" do
    hash1 = @service.hmac_email("test@example.com")
    hash2 = @service.hmac_email("  test@example.com  ")
    assert_equal hash1, hash2
  end

  test "hmac_email generates unique hash for empty email" do
    hash1 = @service.hmac_email("")
    hash2 = @service.hmac_email("")
    # Empty emails generate random UUIDs, so hashes differ
    refute_equal hash1, hash2
  end

  test "hmac_email generates unique hash for nil email" do
    hash1 = @service.hmac_email(nil)
    hash2 = @service.hmac_email(nil)
    refute_equal hash1, hash2
  end

  test "find_or_create_user creates new candidate user" do
    user = @service.find_or_create_user("newuser@example.com")
    assert_equal "candidate", user.role
    assert_equal "demo", user.email_kek_id
    assert user.persisted?
  end

  test "find_or_create_user returns existing user for same email" do
    user1 = @service.find_or_create_user("same@example.com")
    user2 = @service.find_or_create_user("same@example.com")
    assert_equal user1.id, user2.id
  end

  test "uses custom pepper when provided" do
    service_a = EmailIdentityService.new(pepper: "pepper-a")
    service_b = EmailIdentityService.new(pepper: "pepper-b")
    hash_a = service_a.hmac_email("test@example.com")
    hash_b = service_b.hmac_email("test@example.com")
    refute_equal hash_a, hash_b
  end
end
