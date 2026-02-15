## 2025-11-21 - SSRF in LinkedInFetcher
**Vulnerability:** Found `LinkedInFetcher` class in `web/app/services/linked_in_fetcher.rb` (CamelCase file) which was used by `ClaimIdentityController` but lacked host validation, allowing SSRF. Another unused class `LinkedinFetcher` in `web/app/services/linkedin_fetcher.rb` (lowercase file) had the correct validation.
**Learning:** Duplicate classes/files with similar names (likely typos or refactoring leftovers) can hide vulnerabilities. One secure implementation was ignored in favor of an insecure one.
**Prevention:** Remove unused code and audit similar filenames. Use strict linting to catch class/filename mismatches.

## 2025-11-21 - Memory Discrepancy on Input Validation
**Vulnerability:** The Review model was documented in memory as having a 5000 character limit on `text`, but the codebase lacked this validation.
**Learning:** Security documentation or assumptions can drift from the actual code state. Always verify security controls in the source.
**Prevention:** Use automated tests (like the one added) to enforce security invariants rather than relying on documentation.

## 2025-11-21 - Logic Flaw in ClaimIdentityController
**Vulnerability:** The `verify` action in `ClaimIdentityController` verifies a Recruiter profile based on *any* provided LinkedIn URL containing the token, without ensuring that the provided LinkedIn URL belongs to the Recruiter entity.
**Learning:** Verification flows that accept user-provided identity claims (URL) at the *verification* step, without linking them to the *request* step or the entity, are prone to bypass.
**Prevention:** Bind the verification target (e.g. LinkedIn URL) to the entity or the challenge at creation time, and only verify against that bound target.
## 2025-11-22 - Logic Flaw in Identity Verification (Account Takeover)
**Vulnerability:** `ClaimIdentityController#verify` accepted the `linkedin_url` as a user parameter. An attacker could initiate a claim for a victim, place the verification token on their own profile, and verify the claim by supplying their own profile URL to the verification endpoint. This allowed taking over any recruiter account.
**Learning:** Never trust client input for verification parameters that determine the identity source. The source of truth (the URL to check) must be stored securely server-side at the time of initiation (create) and retrieved from the database during verification.
**Prevention:** Store all verification context (URLs, tokens, targets) in the database record (e.g., `IdentityChallenge`) and ignore user parameters that duplicate this state during the verification step.

## 2026-01-26 - Insecure Default Credentials in Duplicated Code
**Vulnerability:** Three admin controllers duplicated `require_moderator_auth` logic, all defaulting to "mod"/"mod" credentials if environment variables were missing. This created a risk of accidental exposure in production if configuration was missed, and violated DRY making it hard to secure them all.
**Learning:** Security logic (authentication/authorization) must be centralized. Duplicated security logic inevitably drifts or relies on unsafe defaults for developer convenience that can leak into production.
**Prevention:** Centralize admin authentication in a base controller (`Admin::BaseController`) and enforce strict credential requirements in production (fail closed if config is missing), allowing unsafe defaults *only* in development/test environments.

## 2026-02-06 - Insecure Default "Pepper" in Duplicated Code
**Vulnerability:** A "pepper" used for hashing emails was duplicated across controllers with a hardcoded insecure default ("demo-only-pepper-not-secret"). If used in production without the ENV variable set, user email privacy would be compromised via rainbow table attacks on the predictable hashes.
**Learning:** Hardcoded secrets (even as defaults) often survive into production. Logic duplicated across controllers is hard to audit and update.
**Prevention:** Centralize security-critical logic (like HMAC generation) in a single authoritative location (e.g., Model or Service). Enforce "fail-secure" behavior by raising exceptions in production if required secrets are missing, rather than falling back to defaults.
