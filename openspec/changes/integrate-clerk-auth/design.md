## Context

The application has no production authentication system. Admin uses HTTP Basic Auth, user sessions are dev/test only, and users are created implicitly via email HMAC. This change replaces all auth with Clerk.com as a managed IDP, using LinkedIn as the primary social connection with email and GitHub as additional backends per role.

Key constraint: all Clerk-specific code must be isolated behind a thin abstraction layer so we can swap providers in the future without touching controllers or business logic.

Reference: [Clerk Ruby SDK](https://github.com/clerk/clerk-sdk-ruby), [Rails integration](https://clerk.com/docs/reference/ruby/rails)

## Goals

- Replace all existing auth (HTTP Basic, dev sessions) with Clerk
- Enforce role-based authentication requirements (auth matrix) server-side
- Isolate Clerk dependency behind a single service + concern (portability)
- Provide test helpers that fix the pre-existing `sign_in_as` gap
- Update all architectural documentation to reflect the new auth model
- Set up local development environment with Clerk dev tier

## Non-Goals

- Recruiter identity verification redesign (separate follow-up openspec — will use k=5 threshold + admin override)
- Migrating existing anonymous user records to Clerk
- Building a custom signup/login UI (use Clerk's hosted components)
- Multi-tenancy or Clerk Organizations

## Decisions

### 1. Clerk SDK integration and configuration

Add `clerk-sdk-ruby` gem. Clerk auto-inserts Rack middleware in Rails.

```ruby
# config/initializers/clerk.rb
Clerk.configure do |config|
  config.secret_key = ENV["CLERK_SECRET_KEY"]
  config.publishable_key = ENV["CLERK_PUBLISHABLE_KEY"]
  config.excluded_routes = [
    "/health",
    "/up",
    "/recruiters",
    "/recruiters/*",
    "/companies",
    "/companies/*",
    "/assets/*",
    "/favicon.ico"
  ]
  config.cache_store = Rails.cache
end
```

Public routes (recruiter listings, company pages, health checks) are excluded from Clerk middleware entirely — no JWT verification overhead on read-heavy public pages.

### 2. AuthenticationService (thin Clerk adapter)

Single service class isolating all Clerk SDK calls. If we swap Clerk, only this file changes.

```ruby
# app/services/authentication_service.rb
class AuthenticationService
  PROVIDER_REQUIREMENTS = {
    candidate_submit: { any_of: [:email, :linkedin] },
    candidate_paid:   { all_of: [:email, :linkedin] },
    recruiter:        { all_of: [:linkedin] },
    admin:            { all_of: [:email, :linkedin, :github], two_factor: true }
  }.freeze

  def initialize(clerk_helper)
    @clerk = clerk_helper
  end

  def authenticated?
    @clerk.user_id.present?
  end

  def user_id
    @clerk.user_id
  end

  def session_claims
    @clerk.session
  end

  def has_provider?(provider)
    case provider
    when :email
      clerk_user.email_addresses.any? { |e| e["verification"]["status"] == "verified" }
    when :linkedin, :github
      clerk_user.external_accounts.any? { |a| a["provider"] == provider.to_s }
    end
  end

  def two_factor_enabled?
    clerk_user.two_factor_enabled
  end

  def meets_requirements?(policy_key)
    reqs = PROVIDER_REQUIREMENTS.fetch(policy_key)
    providers_met = if reqs[:any_of]
      reqs[:any_of].any? { |p| has_provider?(p) }
    elsif reqs[:all_of]
      reqs[:all_of].all? { |p| has_provider?(p) }
    end
    two_factor_met = reqs[:two_factor] ? two_factor_enabled? : true
    providers_met && two_factor_met
  end

  private

  def clerk_user
    @clerk_user ||= @clerk.user
  end
end
```

Note: `clerk_user` triggers a Backend API call (cached 60s). `user_id` and `session_claims` use JWT claims only (no API call). This is a deliberate performance decision — document for future revisit at scale.

### 3. Controller concerns

Two concerns: one for Clerk integration, one for auth policy enforcement.

```ruby
# app/controllers/concerns/clerk_authenticatable.rb
module ClerkAuthenticatable
  extend ActiveSupport::Concern

  included do
    helper_method :current_clerk_user, :authenticated?
  end

  private

  def auth_service
    @auth_service ||= AuthenticationService.new(clerk)
  end

  def current_clerk_user
    auth_service
  end

  def authenticated?
    auth_service.authenticated?
  end

  def require_auth!
    return if authenticated?
    redirect_to clerk.sign_in_url, allow_other_host: true
  end
end
```

```ruby
# app/controllers/concerns/auth_policy.rb
module AuthPolicy
  extend ActiveSupport::Concern

  private

  def require_policy!(policy_key)
    require_auth!
    return if performed?
    unless auth_service.meets_requirements?(policy_key)
      redirect_to complete_profile_path,
        alert: "Please connect required accounts to continue."
    end
  end

  def require_admin!
    require_policy!(:admin)
  end
end
```

### 4. ApplicationController replacement

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include ClerkAuthenticatable
  include AuthPolicy

  # current_user is now current_clerk_user (via helper_method)
  # No more session[:user_id] lookup
end
```

### 5. Admin auth replacement

```ruby
# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
  before_action :require_admin!
end
```

Replaces `authenticate_or_request_with_http_basic` entirely. Admin must have email + LinkedIn + GitHub + 2FA enabled via Clerk.

### 6. Review submission flow

Reviews currently create local users via `EmailIdentityService`. New flow:

1. User authenticates via Clerk (email OR LinkedIn — candidate_submit policy)
2. Review/Interaction stores `clerk_user_id` as author reference
3. For k-anonymity grouping, we HMAC the Clerk email into a `reviewer_hmac` field (preserves existing privacy pattern without local User records)
4. `EmailIdentityService` is deleted — Clerk owns identity

### 7. AccessControlHelper update

```ruby
module AccessControlHelper
  def can_view_details?(resource = nil)
    return false unless authenticated?
    # Admin check via Clerk role/metadata
    return true if auth_service.meets_requirements?(:admin)
    # Paid check via local record or Clerk metadata
    return true if paid_subscriber?
    # Ownership check via clerk_user_id on resource
    return true if resource&.respond_to?(:clerk_user_id) &&
                   resource.clerk_user_id == auth_service.user_id
    false
  end
end
```

### 8. Rack::Attack hybrid rate limiting

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("authenticated/requests", limit: 60, period: 1.minute) do |req|
  # Use Clerk user_id from JWT if present, fall back to IP
  req.env.dig("clerk", "session", "sub") || req.ip
end
```

Authenticated users rate-limited by user ID (more precise than IP). Public requests remain IP-based.

### 9. Test helper

```ruby
# test/helpers/clerk_test_helper.rb
module ClerkTestHelper
  def sign_in_as_clerk(role:, providers: [], two_factor: false, user_id: nil)
    user_id ||= "user_#{SecureRandom.hex(8)}"
    external_accounts = providers.filter_map { |p|
      next if p == :email
      { "provider" => p.to_s, "verification" => { "status" => "verified" } }
    }
    email_addresses = if providers.include?(:email)
      [{ "email_address" => "test@example.com", "verification" => { "status" => "verified" } }]
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

    mock_clerk = OpenStruct.new(
      user_id: user_id,
      user: mock_user,
      session: { "sub" => user_id, "sid" => "sess_#{SecureRandom.hex(8)}" },
      sign_in_url: "/sign-in"
    )

    # Stub the clerk helper on the controller
    ApplicationController.any_instance.stubs(:clerk).returns(mock_clerk)
  end

  def sign_out_clerk
    ApplicationController.any_instance.unstub(:clerk)
  end
end
```

This fixes the pre-existing `sign_in_as` test gap. All tests that previously used `session[:user_id]` or undefined `sign_in_as` will use `sign_in_as_clerk` instead.

### 10. Clerk local development setup

Development uses Clerk's dev instance (free tier, shared OAuth credentials):

```bash
# .env.development (not committed)
CLERK_SECRET_KEY=sk_test_...
CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SIGN_IN_URL=https://<your-clerk-domain>/sign-in
CLERK_SIGN_UP_URL=https://<your-clerk-domain>/sign-up
```

Clerk dev instances provide:
- Pre-configured LinkedIn OIDC (no custom OAuth app needed)
- Test mode for automated testing
- Dashboard for user management

## Risks / Trade-offs

- **Clerk dependency**: We're outsourcing auth to a third party. Mitigated by the `AuthenticationService` abstraction — one file to swap. If Clerk disappears, we can move to Auth0, Firebase Auth, or roll our own.
- **No offline auth**: Clerk middleware needs to verify JWTs (can do locally with JWKS caching) but full user fetches need network. Mitigated by using JWT claims for hot path.
- **Cost at scale**: Clerk free tier has limits. At scale, this becomes a line-item cost. Acceptable for POC.
- **Test coupling**: Stubbing `clerk` helper in tests is pragmatic but couples to Clerk's API shape. The `ClerkTestHelper` centralizes this so changes are in one place.
- **Existing user data**: Old anonymous users with `email_hmac` but no `clerk_user_id` become orphaned. This is intentional (clean break). Their reviews remain attributed to the HMAC identity.

## Migration Plan

1. Add `clerk-sdk-ruby` gem, create initializer and excluded routes
2. Create `AuthenticationService`, `ClerkAuthenticatable`, and `AuthPolicy` concerns
3. Update `ApplicationController` to use new concerns
4. Replace `Admin::BaseController` HTTP Basic Auth with Clerk + admin policy
5. Update `AccessControlHelper` to use Clerk identity
6. Update review submission flow — store `clerk_user_id`, delete `EmailIdentityService`
7. Remove `SessionsController` and session routes
8. Update `Rack::Attack` to hybrid rate limiting
9. Create `ClerkTestHelper`, migrate all tests
10. Create `auth_policy_test.rb` with full matrix coverage
11. Update documentation: `project.md`, `gameplan.md`, `GEMINI.md`, `TESTING_STANDARDS.md`
12. Set up Clerk dev instance and verify locally
13. Run full test suite
