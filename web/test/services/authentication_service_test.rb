require "test_helper"

class AuthenticationServiceTest < ActiveSupport::TestCase
  # Build a fake Clerk helper (same structure as FakeClerkMiddleware injects).
  # Uses OpenStruct objects to match the Clerk SDK v5 typed model interface
  # (attribute methods, not hash key access).
  def clerk_mock(user_id: "user_abc", email: true, linkedin: false, github: false, two_factor: false)
    external_accounts = []
    external_accounts << OpenStruct.new(provider: "linkedin") if linkedin
    external_accounts << OpenStruct.new(provider: "github")   if github

    verified_email  = OpenStruct.new(verification: OpenStruct.new(status: "verified"))
    email_addresses = email ? [verified_email] : []

    mock_user = OpenStruct.new(
      id: user_id,
      email_addresses: email_addresses,
      external_accounts: external_accounts,
      two_factor_enabled: two_factor,
      public_metadata: {}
    )

    OpenStruct.new(user_id: user_id, user: mock_user)
  end

  def unauthenticated_clerk
    OpenStruct.new(user_id: nil, user: nil)
  end

  # --- authenticated? ---

  test "authenticated? returns false when clerk is nil" do
    service = AuthenticationService.new(nil)
    assert_not service.authenticated?
  end

  test "authenticated? returns false when user_id is nil" do
    service = AuthenticationService.new(unauthenticated_clerk)
    assert_not service.authenticated?
  end

  test "authenticated? returns true when user_id is present" do
    service = AuthenticationService.new(clerk_mock)
    assert service.authenticated?
  end

  # --- has_provider? ---

  test "has_provider?(:email) returns true when verified email present" do
    service = AuthenticationService.new(clerk_mock(email: true))
    assert service.has_provider?(:email)
  end

  test "has_provider?(:email) returns false when no email addresses" do
    service = AuthenticationService.new(clerk_mock(email: false))
    assert_not service.has_provider?(:email)
  end

  test "has_provider?(:email) returns false when email unverified" do
    unverified_email = OpenStruct.new(verification: OpenStruct.new(status: "unverified"))
    mock_user = OpenStruct.new(
      id: "user_x",
      email_addresses: [unverified_email],
      external_accounts: [],
      two_factor_enabled: false
    )
    clerk = OpenStruct.new(user_id: "user_x", user: mock_user)
    service = AuthenticationService.new(clerk)
    assert_not service.has_provider?(:email)
  end

  test "has_provider?(:linkedin) returns true when linkedin in external_accounts" do
    service = AuthenticationService.new(clerk_mock(linkedin: true))
    assert service.has_provider?(:linkedin)
  end

  test "has_provider?(:linkedin) returns false when linkedin absent" do
    service = AuthenticationService.new(clerk_mock(linkedin: false))
    assert_not service.has_provider?(:linkedin)
  end

  test "has_provider?(:github) returns true when github in external_accounts" do
    service = AuthenticationService.new(clerk_mock(github: true))
    assert service.has_provider?(:github)
  end

  test "has_provider?(:github) returns false when github absent" do
    service = AuthenticationService.new(clerk_mock(github: false))
    assert_not service.has_provider?(:github)
  end

  test "has_provider? returns false for unknown provider" do
    service = AuthenticationService.new(clerk_mock)
    assert_not service.has_provider?(:twitter)
  end

  test "has_provider? returns false when unauthenticated" do
    service = AuthenticationService.new(unauthenticated_clerk)
    assert_not service.has_provider?(:email)
  end

  # --- two_factor_enabled? ---

  test "two_factor_enabled? returns true when enabled" do
    service = AuthenticationService.new(clerk_mock(two_factor: true))
    assert service.two_factor_enabled?
  end

  test "two_factor_enabled? returns false when disabled" do
    service = AuthenticationService.new(clerk_mock(two_factor: false))
    assert_not service.two_factor_enabled?
  end

  test "two_factor_enabled? returns false when unauthenticated" do
    service = AuthenticationService.new(unauthenticated_clerk)
    assert_not service.two_factor_enabled?
  end

  # --- meets_requirements? ---

  test "meets_requirements?(:candidate_submit) passes with email only" do
    service = AuthenticationService.new(clerk_mock(email: true, linkedin: false))
    assert service.meets_requirements?(:candidate_submit)
  end

  test "meets_requirements?(:candidate_submit) passes with linkedin only" do
    service = AuthenticationService.new(clerk_mock(email: false, linkedin: true))
    assert service.meets_requirements?(:candidate_submit)
  end

  test "meets_requirements?(:candidate_submit) fails with no providers" do
    service = AuthenticationService.new(clerk_mock(email: false, linkedin: false))
    assert_not service.meets_requirements?(:candidate_submit)
  end

  test "meets_requirements?(:candidate_paid) passes with both email and linkedin" do
    service = AuthenticationService.new(clerk_mock(email: true, linkedin: true))
    assert service.meets_requirements?(:candidate_paid)
  end

  test "meets_requirements?(:candidate_paid) fails with email only" do
    service = AuthenticationService.new(clerk_mock(email: true, linkedin: false))
    assert_not service.meets_requirements?(:candidate_paid)
  end

  test "meets_requirements?(:candidate_paid) fails with linkedin only" do
    service = AuthenticationService.new(clerk_mock(email: false, linkedin: true))
    assert_not service.meets_requirements?(:candidate_paid)
  end

  test "meets_requirements?(:recruiter) passes with linkedin" do
    service = AuthenticationService.new(clerk_mock(linkedin: true))
    assert service.meets_requirements?(:recruiter)
  end

  test "meets_requirements?(:recruiter) fails without linkedin" do
    service = AuthenticationService.new(clerk_mock(linkedin: false))
    assert_not service.meets_requirements?(:recruiter)
  end

  test "meets_requirements?(:admin) passes with all providers and 2FA" do
    service = AuthenticationService.new(clerk_mock(email: true, linkedin: true, github: true, two_factor: true))
    assert service.meets_requirements?(:admin)
  end

  test "meets_requirements?(:admin) fails when github is missing" do
    service = AuthenticationService.new(clerk_mock(email: true, linkedin: true, github: false, two_factor: true))
    assert_not service.meets_requirements?(:admin)
  end

  test "meets_requirements?(:admin) fails when 2FA is missing" do
    service = AuthenticationService.new(clerk_mock(email: true, linkedin: true, github: true, two_factor: false))
    assert_not service.meets_requirements?(:admin)
  end

  test "meets_requirements?(:admin) fails when unauthenticated" do
    service = AuthenticationService.new(unauthenticated_clerk)
    assert_not service.meets_requirements?(:admin)
  end

  test "meets_requirements? raises KeyError for unknown policy" do
    service = AuthenticationService.new(clerk_mock)
    assert_raises(KeyError) { service.meets_requirements?(:nonexistent_policy) }
  end
end
