# Change: Close Test Coverage Gaps

## Why
Code review identified critical test coverage gaps:
1. Five core models (Company, Experience, IdentityChallenge, ProfileClaim, TakedownRequest) have zero unit tests — validations and edge cases are only covered indirectly.
2. BackupService has 2 tests covering the happy path only — no error path coverage for a service that handles the entire database.
3. No security-focused tests exist for rate limiting, auth boundaries, or PII leak prevention.
4. LinkedInFetcher (the version we're keeping after consolidation) has no tests at all — including the host validation that's a security boundary.

Per engineering preferences: "well-tested code is non-negotiable; too many tests > too few."

## What Changes
- **New model unit tests**: Validations, associations, state transitions, and edge cases for 5 models.
- **New BackupService error tests**: Every failure mode (pg_dump, encryption, upload, prune) verified to trigger notification.
- **New security integration tests**: Rate limiting smoke tests, admin auth boundary tests, PII leak assertions.
- **New LinkedInFetcher tests**: Host validation, timeout, empty body, malformed URL, large response.

## Impact
- **New Files**:
  - `web/test/models/company_test.rb`
  - `web/test/models/experience_test.rb`
  - `web/test/models/identity_challenge_test.rb`
  - `web/test/models/profile_claim_test.rb`
  - `web/test/models/takedown_request_test.rb`
  - `web/test/services/linkedin_fetcher_test.rb`
  - `web/test/integration/security_test.rb`
- **Modified Files**:
  - `web/test/services/backup_service_test.rb` (add error path tests)
- **Affected Specs**: None
