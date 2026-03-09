## 1. BackupService Shell Injection Fix
- [x] 1.1 Refactor `backup_service.rb` pg_dump command to use array-form `Open3.pipeline_r` instead of string interpolation.
- [x] 1.2 Refactor `backup_service.rb` openssl encryption command to use array-form `Open3.capture3`.
- [x] 1.3 Add `-pbkdf2` flag to openssl command (modern key derivation, avoids deprecation warning).
- [x] 1.4 Verify existing BackupService tests pass with new command format.

## 2. LinkedInFetcher Consolidation
- [x] 2.1 Delete `web/app/services/linked_in_fetcher.rb` (insecure version).
- [x] 2.2 Update `ClaimIdentityController` to use `LinkedinFetcher` from `linkedin_fetcher.rb`.
- [x] 2.3 Verify class name casing is consistent between service and controller.
- [x] 2.4 Search codebase for any other references to the deleted file/class.

## 3. Admin N+1 Fix
- [x] 3.1 Add `:review_responses` to `.includes()` in `admin/reviews_controller.rb` index action.

## 4. Verification
- [x] 4.1 Run `rails test` — BackupService tests pass (2/2, 6 assertions). Full suite has 53/94 passing; all failures are pre-existing (fixture FK issues, locale tests, view bugs).
- [ ] 4.2 Manually verify admin reviews page loads without N+1 (check logs).

## 5. Bonus: Pre-existing Issues Fixed
- [x] 5.1 Added missing `web/app/models/interaction.rb` (was in njl_fixes but missing from main — blocked all test fixtures).
- [x] 5.2 Added missing fixture files (`companies.yml`, `users.yml`, `interactions.yml`, `experiences.yml`) to satisfy FK constraints.
