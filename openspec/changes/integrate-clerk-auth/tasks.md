## 1. Clerk SDK Setup
- [ ] 1.1 Add `gem 'clerk-sdk-ruby', require: "clerk"` to Gemfile
- [ ] 1.2 Run `bundle install`
- [ ] 1.3 Create `web/config/initializers/clerk.rb` with configuration (secret_key, publishable_key, excluded_routes, cache_store)
- [ ] 1.4 Add Clerk env vars to `.env.development` (not committed) and document in GEMINI.md
- [ ] 1.5 Verify Clerk middleware loads in Rails middleware stack

## 2. AuthenticationService
- [ ] 2.1 Create `web/app/services/authentication_service.rb` with PROVIDER_REQUIREMENTS, authenticated?, user_id, session_claims, has_provider?, two_factor_enabled?, meets_requirements?
- [ ] 2.2 Unit test AuthenticationService with mocked Clerk helper (all policy keys, edge cases)

## 3. Controller Concerns
- [ ] 3.1 Create `web/app/controllers/concerns/clerk_authenticatable.rb` (auth_service, current_clerk_user, authenticated?, require_auth!)
- [ ] 3.2 Create `web/app/controllers/concerns/auth_policy.rb` (require_policy!, require_admin!)
- [ ] 3.3 Update `web/app/controllers/application_controller.rb` — include both concerns, remove old current_user and session[:user_id] lookup

## 4. Admin Auth Migration
- [ ] 4.1 Replace `web/app/controllers/admin/base_controller.rb` — remove HTTP Basic Auth, add `before_action :require_admin!`
- [ ] 4.2 Remove `DEMO_MOD_USER` / `DEMO_MOD_PASSWORD` references from codebase

## 5. Access Control Update
- [ ] 5.1 Update `web/app/helpers/access_control_helper.rb` — use `authenticated?` and `auth_service` instead of `current_user`
- [ ] 5.2 Define `paid_subscriber?` check (Clerk metadata or local record lookup by clerk_user_id)

## 6. Review Submission Flow
- [ ] 6.1 Update review/interaction creation to store `clerk_user_id` as author reference
- [ ] 6.2 Add `clerk_user_id` column to relevant tables (migration)
- [ ] 6.3 Preserve k-anonymity by HMACing Clerk email into `reviewer_hmac`
- [ ] 6.4 Delete `web/app/services/email_identity_service.rb`
- [ ] 6.5 Update any controllers that called `EmailIdentityService`

## 7. Remove Old Auth Code
- [ ] 7.1 Delete `web/app/controllers/sessions_controller.rb`
- [ ] 7.2 Remove session routes from `web/config/routes.rb` (/login, /logout, /utils/login)
- [ ] 7.3 Remove any remaining `session[:user_id]` references in non-test code

## 8. Rate Limiting
- [ ] 8.1 Update `web/config/initializers/rack_attack.rb` — hybrid throttle using Clerk user_id from JWT when present, IP otherwise
- [ ] 8.2 Verify public routes still rate-limit by IP

## 9. Test Infrastructure
- [ ] 9.1 Create `web/test/helpers/clerk_test_helper.rb` with `sign_in_as_clerk(role:, providers:, two_factor:)` and `sign_out_clerk`
- [ ] 9.2 Include `ClerkTestHelper` in `test_helper.rb`
- [ ] 9.3 Migrate all admin tests from `auth_headers` (HTTP Basic) to `sign_in_as_clerk(role: :admin, ...)`
- [ ] 9.4 Migrate all tests using `session[:user_id]` to `sign_in_as_clerk`
- [ ] 9.5 Migrate all tests using undefined `sign_in_as` to `sign_in_as_clerk`
- [ ] 9.6 Remove old `auth_headers` helper methods from test files

## 10. Auth Policy Tests
- [ ] 10.1 Create `web/test/integration/auth_policy_test.rb`
- [ ] 10.2 Test: candidate with email can submit review
- [ ] 10.3 Test: candidate with LinkedIn can submit review
- [ ] 10.4 Test: unauthenticated user cannot submit review
- [ ] 10.5 Test: paid subscriber requires email AND LinkedIn
- [ ] 10.6 Test: recruiter claiming profile requires LinkedIn
- [ ] 10.7 Test: admin requires email + LinkedIn + GitHub + 2FA
- [ ] 10.8 Test: admin without 2FA is rejected
- [ ] 10.9 Test: admin without GitHub is rejected
- [ ] 10.10 Test: unauthenticated user can access public routes (recruiter listings, company pages)

## 11. Documentation Updates
- [ ] 11.1 Update `openspec/project.md` — auth architecture section (Clerk as IDP, auth matrix, remove email HMAC user creation, update external dependencies)
- [ ] 11.2 Update `gameplan.md` — identity/verification section, threat model (add Clerk dependency risk)
- [ ] 11.3 Update `GEMINI.md` — add Clerk env vars (CLERK_SECRET_KEY, CLERK_PUBLISHABLE_KEY, CLERK_SIGN_IN_URL, CLERK_SIGN_UP_URL), remove DEMO_MOD_USER/DEMO_MOD_PASSWORD
- [ ] 11.4 Update `TESTING_STANDARDS.md` — document ClerkTestHelper, sign_in_as_clerk usage, Clerk test mode
- [ ] 11.5 Document performance decision: JWT claims for hot path, full user fetch only for provider checks (revisit at scale)

## 12. Local Development Setup
- [ ] 12.1 Configure Clerk dev instance in dashboard (enable LinkedIn OIDC, email, GitHub social connections)
- [ ] 12.2 Set up admin user in Clerk with all required providers + 2FA
- [ ] 12.3 Verify sign-in flow works locally with Clerk hosted UI
- [ ] 12.4 Verify excluded routes are accessible without auth

## 13. Verification
- [ ] 13.1 Run `rails test` — confirm no regressions from auth migration
- [ ] 13.2 Confirm pre-existing failures (review_metrics bug, locale issues) are unchanged
- [ ] 13.3 Confirm `sign_in_as` failures are resolved by ClerkTestHelper
- [ ] 13.4 Manual smoke test: public pages, auth flow, admin access, review submission
