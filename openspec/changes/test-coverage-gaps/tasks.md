## 1. Model Unit Tests
- [x] 1.1 Create `web/test/models/company_test.rb` — validations, associations, size bucketing edge cases (7 tests).
- [x] 1.2 Create `web/test/models/experience_test.rb` — rating boundaries (1-5), status transitions, interaction association (11 tests).
- [x] 1.3 Create `web/test/models/identity_challenge_test.rb` — token lifecycle, expiration, polymorphic subject, verified_at (9 tests).
- [x] 1.4 Create `web/test/models/profile_claim_test.rb` — verification methods, recruiter/user associations, state management (9 tests).
- [x] 1.5 Create `web/test/models/takedown_request_test.rb` — polymorphic subject, status transitions, SLA dates (9 tests).
- [x] 1.6 Add required fixtures — expanded `users.yml` with `candidate_paid`, `candidate_free`, `admin`, `owner`, `moderator` (fixes pre-existing fixture errors).

## 2. BackupService Error Path Tests
- [x] 2.1 Test pg_dump failure → BackupError raised, failure notification sent.
- [x] 2.2 Test encryption failure → BackupError raised.
- [x] 2.3 Test upload failure → error raised, failure notification sent.
- [x] 2.4 Test missing database (RenderApiClient returns nil) → BackupError before dump.
- [x] 2.5 Test prune with malformed filenames → logs warning, no crash.
- [x] 2.6 Test file cleanup in ensure block when operations fail mid-stream.
- [x] 2.7 Test missing connection string → BackupError raised.

## 3. Security Integration Tests
- [x] 3.1 Create `web/test/integration/security_test.rb`.
- [x] 3.2 Test admin endpoints return 401 without credentials (reviews + dashboard).
- [x] 3.3 Test admin endpoints return 401 with wrong credentials (reviews + dashboard).
- [x] 3.4 Test admin endpoints return 200 with correct credentials (reviews + dashboard).
- [x] 3.5 Test PII leak prevention — no raw email in JSON API responses (recruiters, companies, review submission).
- [ ] 3.6 Test rate limiting — skipped (no rate limiting middleware currently configured).

## 4. LinkedInFetcher Tests
- [x] 4.1 Create `web/test/services/linkedin_fetcher_test.rb`.
- [x] 4.2 Test valid LinkedIn URL returns response body.
- [x] 4.3 Test non-LinkedIn domain rejected (ALLOWED_HOSTS).
- [x] 4.4 Test timeout returns nil and logs warning.
- [x] 4.5 Test malformed URL returns nil.
- [x] 4.6 Test HTTP error status returns nil.
- [x] 4.7 Test empty string URL returns nil.
- [x] 4.8 Test subdomain (www.linkedin.com) accepted.
- [x] 4.9 Test timeout configuration (default, custom, negative fallback).

## 5. Verification
- [x] 5.1 Run full `rails test` — 176 runs, 159 pass, 6 failures + 9 errors (all pre-existing), 2 skips.
- [x] 5.2 Test count increased from 102 → 176 (+74 new tests). Errors reduced from 11 → 9 (fixture fix).
