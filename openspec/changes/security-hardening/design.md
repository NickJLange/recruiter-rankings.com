## Context
A BIG CHANGE code review surfaced three security-relevant issues. All are low-effort fixes to existing code — no new features or architectural changes.

## Goals / Non-Goals
- **Goals**:
  - Eliminate shell injection in BackupService by using array-form Open3.
  - Consolidate to single, robust LinkedInFetcher with host validation.
  - Fix N+1 query on admin reviews page.
- **Non-Goals**:
  - Rewriting BackupService architecture (separate change).
  - Adding new LinkedInFetcher features.
  - Performance optimization beyond the one-line N+1 fix.

## Decisions

### BackupService Shell Injection Fix
Replace string-form shell commands:
```ruby
# BEFORE (vulnerable)
dump_command = "pg_dump \"#{connection_string}\" | gzip > #{temp_file}"
Open3.capture3(dump_command)

# AFTER (safe)
Open3.pipeline_r(
  ["pg_dump", connection_string],
  ["gzip"]
) do |output, wait_threads|
  File.open(temp_file, "wb") { |f| IO.copy_stream(output, f) }
end
```

For encryption, replace string interpolation with array-form:
```ruby
# BEFORE (vulnerable)
Open3.capture3("openssl enc -aes-256-cbc -salt -in #{temp_file} -out #{encrypted_file} -k \"#{encryption_key}\"")

# AFTER (safe)
Open3.capture3("openssl", "enc", "-aes-256-cbc", "-salt", "-pbkdf2",
  "-in", temp_file, "-out", encrypted_file, "-k", encryption_key)
```

### LinkedInFetcher Consolidation
- Delete `web/app/services/linked_in_fetcher.rb` (no host validation, swallows errors silently).
- Keep `web/app/services/linkedin_fetcher.rb` (has `ALLOWED_HOSTS`, logs failures).
- Update `ClaimIdentityController` to reference the correct class.

### Admin N+1 Fix
Add `:review_responses` to the existing `.includes()` in `admin/reviews_controller.rb`.

## Risks / Trade-offs
- **BackupService**: Array-form Open3 doesn't use shell piping. Need `Open3.pipeline_r` or equivalent for the pg_dump | gzip pipe. Test carefully.
- **LinkedInFetcher**: Verify the class name casing matches (`LinkedinFetcher` vs `LinkedInFetcher`) — the two files used different casing.

## Migration Plan
- No data migration needed. Code-only changes.
- Run `rails test` to verify no regressions.
