module ClerkTestHelper
  # Simulates a signed-in Clerk session for integration tests by injecting a
  # fake Clerk::Proxy into request.env['clerk'] via thread-local state.
  # The FakeClerkMiddleware (test-only) reads this thread-local on each request.
  #
  # For system tests (real browser, different thread), ApplicationSystemTestCase
  # overrides this to use the cookie-based class-level store in FakeClerkMiddleware.
  #
  # Parameters:
  #   role:        :candidate, :admin, etc. (stored in public_metadata["role"])
  #   providers:   array of :email, :linkedin, :github — which accounts are connected
  #   two_factor:  whether two_factor_enabled is true
  #   user_id:     override the auto-generated Clerk user ID
  def sign_in_as_clerk(role: :candidate, providers: [:email], two_factor: false, user_id: nil)
    mock_clerk = build_clerk_mock(role: role, providers: providers, two_factor: two_factor, user_id: user_id)
    Thread.current[:fake_clerk] = mock_clerk
    mock_clerk
  end

  def sign_out_clerk
    Thread.current[:fake_clerk] = nil
  end

  def teardown
    sign_out_clerk
    super
  end

  private

  def build_clerk_mock(role:, providers:, two_factor:, user_id: nil)
    user_id ||= "user_#{SecureRandom.hex(8)}"

    external_accounts = providers.filter_map do |p|
      next if p == :email
      { "provider" => p.to_s, "verification" => { "status" => "verified" } }
    end

    email_addresses = if providers.include?(:email)
      [{ "email_address" => "test+#{user_id}@example.com", "verification" => { "status" => "verified" } }]
    else
      []
    end

    mock_user = OpenStruct.new(
      id: user_id,
      email_addresses: email_addresses,
      external_accounts: external_accounts,
      two_factor_enabled: two_factor,
      public_metadata: { "role" => role.to_s }
    )

    OpenStruct.new(
      user?: true,
      user_id: user_id,
      user: mock_user,
      session: { "sub" => user_id, "sid" => "sess_#{SecureRandom.hex(8)}" },
      sign_in_url: "/sign-in"
    )
  end
end
