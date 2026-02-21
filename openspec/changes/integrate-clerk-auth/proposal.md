# Change: Integrate Clerk as Identity Provider

## Why
The platform currently has no production-ready authentication. Admin uses HTTP Basic Auth with env var credentials. User sessions exist only in dev/test (no login flow in production). There is no OAuth, no Devise, no password system. This blocks every feature that requires knowing who a user is — paid subscriptions, recruiter profile claims, review attribution, and admin access control.

Clerk.com provides a managed IDP that handles OAuth (LinkedIn, GitHub), email verification, MFA, and session management. Adopting Clerk as the sole auth provider eliminates the need to build and maintain auth infrastructure while giving us LinkedIn-based identity verification — critical for recruiter verification and candidate trust.

## What Changes

### New files
- `web/app/services/authentication_service.rb` — thin Clerk adapter (portable, single swap point)
- `web/app/controllers/concerns/clerk_authenticatable.rb` — controller concern wrapping Clerk helpers
- `web/app/controllers/concerns/auth_policy.rb` — role-based provider requirements enforcement
- `web/test/helpers/clerk_test_helper.rb` — test helper replacing `sign_in_as`
- `web/test/integration/auth_policy_test.rb` — auth matrix coverage
- `web/config/initializers/clerk.rb` — Clerk SDK configuration

### Modified files
- `web/Gemfile` — add `clerk-sdk-ruby`
- `web/app/controllers/application_controller.rb` — replace `current_user` with Clerk-backed version
- `web/app/controllers/admin/base_controller.rb` — replace HTTP Basic Auth with Clerk + role/2FA policy
- `web/app/helpers/access_control_helper.rb` — update to use Clerk identity
- `web/config/routes.rb` — remove session routes, add Clerk callback routes if needed
- `web/config/initializers/rack_attack.rb` — hybrid rate limiting (user ID when authenticated, IP when not)
- All admin integration tests — migrate from `auth_headers` to `sign_in_as_clerk`
- All tests using `session[:user_id]` — migrate to `ClerkTestHelper`

### Removed files
- `web/app/controllers/sessions_controller.rb` — replaced by Clerk
- `web/app/services/email_identity_service.rb` — replaced by Clerk identity

### Documentation updates
- `openspec/project.md` — auth architecture, Clerk as IDP, remove email HMAC user creation references, update external dependencies
- `gameplan.md` — update identity/verification and threat model sections
- `GEMINI.md` — add Clerk env vars, remove `DEMO_MOD_USER`/`DEMO_MOD_PASSWORD`
- `TESTING_STANDARDS.md` — document Clerk test mode and `ClerkTestHelper`

## Impact
- **Auth matrix enforced server-side**:
  - Candidate (submit review): Email OR LinkedIn
  - Candidate (paid subscriber): Email AND LinkedIn
  - Recruiter (claiming profile): LinkedIn
  - Admin/Moderator: Email + LinkedIn + GitHub + 2FA
- **No local User model for auth** — Clerk is the source of truth for identity. Local records keyed by `clerk_user_id` for app-specific data only.
- **Existing users not migrated** — clean break (option B). Old anonymous records remain as-is.
- **Portability** — all Clerk-specific code isolated in `AuthenticationService` + concern. One seam to swap providers.
- **Performance** — JWT claims used for hot path auth checks; full Clerk user fetch only when checking provider requirements. Public routes excluded from Clerk middleware.
