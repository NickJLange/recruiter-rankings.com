# Proposal: Wire Up LinkedinFetcher for Auto-Verification

## Status
Draft — 2026-03-09

---

## Why This Change Is Needed

`LinkedinFetcher` is a service class that fetches LinkedIn profile pages via HTTP. It exists with timeout handling, host allowlisting, and error logging — but no controller, job, or service calls it. The current claim flow (`ClaimIdentityController`) uses manual admin verification rather than automated LinkedIn profile matching.

The service was built to support automated profile verification: fetch a candidate's LinkedIn page and confirm identity markers match the claimed recruiter profile.

---

## What This Change Does

- Integrate `LinkedinFetcher` into the recruiter claim verification flow
- Add a background job that fetches and parses LinkedIn profiles when a claim is submitted
- Use parsed data to auto-approve or flag claims for admin review
- Add tests for the integration path

---

## What This Change Does NOT Do

- Rewrite `LinkedinFetcher` (the HTTP client is functional as-is)
- Replace admin override capability (admins can still manually approve/reject)
- Scrape LinkedIn at scale (single-profile fetch per claim, respecting rate limits)

---

## Impact Assessment

| Area | Impact |
|------|--------|
| Jobs | New background job for LinkedIn fetch + parse |
| Controllers | `ClaimIdentityController` triggers async verification |
| Services | `LinkedinFetcher` called from new job; may need a parser companion service |
| Tests | Integration tests for the async verification flow |
