## 1. Model Unit Tests
- [ ] 1.1 Create `web/test/models/company_test.rb` — validations, associations, size bucketing edge cases.
- [ ] 1.2 Create `web/test/models/experience_test.rb` — rating boundaries (1-5), status transitions, interaction association.
- [ ] 1.3 Create `web/test/models/identity_challenge_test.rb` — token lifecycle, expiration, polymorphic subject, verified_at.
- [ ] 1.4 Create `web/test/models/profile_claim_test.rb` — verification methods, recruiter/user associations, state management.
- [ ] 1.5 Create `web/test/models/takedown_request_test.rb` — polymorphic subject, status transitions, SLA dates.
- [ ] 1.6 Add any required fixtures for new model tests.

## 2. BackupService Error Path Tests
- [ ] 2.1 Test pg_dump failure → BackupError raised, failure notification sent.
- [ ] 2.2 Test encryption failure → BackupError raised, temp files cleaned up.
- [ ] 2.3 Test upload failure → BackupError raised, failure notification sent.
- [ ] 2.4 Test missing database (RenderApiClient returns nil) → BackupError before dump.
- [ ] 2.5 Test prune with malformed filenames → logs warning, no crash.
- [ ] 2.6 Test file cleanup in ensure block when operations fail mid-stream.

## 3. Security Integration Tests
- [ ] 3.1 Create `web/test/integration/security_test.rb`.
- [ ] 3.2 Test admin endpoints return 401 without credentials.
- [ ] 3.3 Test admin endpoints return 401 with wrong credentials.
- [ ] 3.4 Test admin endpoints return 200 with correct credentials.
- [ ] 3.5 Test PII leak prevention — no raw email in JSON API responses.
- [ ] 3.6 Test rate limiting — verify throttling after threshold exceeded.

## 4. LinkedInFetcher Tests
- [ ] 4.1 Create `web/test/services/linkedin_fetcher_test.rb`.
- [ ] 4.2 Test valid LinkedIn URL returns response body.
- [ ] 4.3 Test non-LinkedIn domain rejected (ALLOWED_HOSTS).
- [ ] 4.4 Test timeout returns nil and logs warning.
- [ ] 4.5 Test malformed URL returns nil.
- [ ] 4.6 Test HTTP error status returns nil.

## 5. Verification
- [ ] 5.1 Run full `rails test` — all new and existing tests pass.
- [ ] 5.2 Verify test count increased by expected amount.
