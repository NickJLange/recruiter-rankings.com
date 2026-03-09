# Change: Security Hardening

## Why
Code review identified three security-relevant issues in existing code:
1. Shell injection vulnerability in `BackupService` — connection strings and encryption keys interpolated directly into shell commands via string concatenation.
2. Duplicate `LinkedInFetcher` implementations — the controller uses the *insecure* version that accepts arbitrary URLs (no host validation), while a robust version with `ALLOWED_HOSTS` checking sits unused.
3. N+1 query on admin reviews page leaks performance but also indicates missing eager-loading discipline.

These are low-effort, high-impact fixes that reduce attack surface and eliminate dead code.

## What Changes
- **BackupService**: Replace string-interpolated shell commands with array-form `Open3.capture3` to eliminate shell injection.
- **LinkedInFetcher**: Delete `linked_in_fetcher.rb` (insecure), update `ClaimIdentityController` to use `linkedin_fetcher.rb` (has host validation + logging).
- **Admin Reviews**: Add `:review_responses` to `.includes()` call (one-line fix).

## Impact
- **Affected Code**:
  - `web/app/services/backup_service.rb` (refactor shell commands)
  - `web/app/services/linked_in_fetcher.rb` (delete)
  - `web/app/services/linkedin_fetcher.rb` (keep, no changes)
  - `web/app/controllers/claim_identity_controller.rb` (update require/class reference)
  - `web/app/controllers/admin/reviews_controller.rb` (add eager load)
- **Affected Specs**: None (no spec changes, code-only fixes)
