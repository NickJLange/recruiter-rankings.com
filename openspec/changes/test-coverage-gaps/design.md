## Context
The codebase has good integration test coverage for happy paths but lacks unit tests for models, error path coverage for services, and security boundary tests. This change adds tests only — no production code changes.

## Goals / Non-Goals
- **Goals**:
  - Unit test all 5 untested models (validations, associations, edge cases).
  - Test every BackupService failure mode and verify notifications fire.
  - Add security smoke tests for rate limiting, auth boundaries, and PII protection.
  - Fully test LinkedInFetcher including host validation security boundary.
- **Non-Goals**:
  - Changing production code (test-only change).
  - Achieving 100% line coverage (focus on risk-weighted coverage).
  - System/browser tests (integration and unit only).

## Decisions

### Model Unit Tests
For each model, test:
- Required validations (presence, inclusion, format)
- Association integrity (belongs_to, has_many)
- Callbacks (slug generation, status defaults)
- Edge cases (boundary values for ratings, expired tokens, invalid status transitions)

### BackupService Error Path Tests
Test these failure scenarios with stubs:
- `pg_dump` returns non-zero exit status → raises `BackupError`, sends failure notification
- `openssl` encryption fails → raises `BackupError`, cleans up temp files
- Storage adapter upload fails → raises, sends failure notification
- `RenderApiClient.find_database_by_name` returns nil → raises before dump
- Prune with malformed timestamps → logs warning, doesn't crash

### Security Integration Tests
- **Rate limiting**: Submit > threshold requests, verify 429 response
- **Auth boundaries**: Hit admin endpoints without credentials → 401; with wrong credentials → 401; with correct credentials → 200
- **PII leak prevention**: Submit review with email, verify JSON responses contain HMAC hash only (no raw email)

### LinkedInFetcher Tests
- Valid LinkedIn URL → returns body
- Non-LinkedIn domain → returns nil (ALLOWED_HOSTS rejection)
- Timeout → returns nil, logs warning
- Malformed URL → returns nil
- Empty response body → returns nil or empty string
- HTTP error status → returns nil

## Risks / Trade-offs
- **Test isolation**: Service tests should use stubs/mocks for external calls (Open3, Net::HTTP). Integration tests should hit real controllers.
- **Fixtures**: New model tests may need additional fixtures. Prefer `build` over `create` where possible to keep tests fast.

## Migration Plan
- Test-only change. No production code or data changes.
- Run `rails test` to verify all new and existing tests pass.
