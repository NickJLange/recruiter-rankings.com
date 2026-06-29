# Proposal: Wire Up TakedownRequest and ProfileClaim Models

## Status
Draft — 2026-03-09

---

## Why This Change Is Needed

`TakedownRequest` and `ProfileClaim` are speculative models that exist in the codebase with database tables, validations, and associations — but no routes, controllers, views, or runtime code references them. They were created as placeholders during early development.

These models represent real future needs:
- **TakedownRequest**: Recruiters or subjects of reviews should be able to request content removal (legal, factual disputes, harassment).
- **ProfileClaim**: Tracks the association between a `User` and a `Recruiter` profile they claim ownership of. Currently, the `ClaimIdentityController` writes directly to `recruiters.verified_at` without creating a `ProfileClaim` record.

Until these are wired into actual user flows, they are dead code.

---

## What This Change Does

- Wire `TakedownRequest` into an admin moderation flow (admin UI to view/resolve requests, public-facing form to submit)
- Wire `ProfileClaim` into the existing `ClaimIdentityController` so claim attempts are tracked as records with audit history
- Add routes, controllers, views, and tests for both

---

## What This Change Does NOT Do

- Delete these models (they represent real domain concepts)
- Change the existing claim verification flow beyond adding record-keeping

---

## Impact Assessment

| Area | Impact |
|------|--------|
| Routes | New public + admin routes for takedown requests; ProfileClaim integrated into existing claim flow |
| Controllers | New `TakedownRequestsController`, updates to `ClaimIdentityController` |
| Admin | New admin views for takedown request queue |
| Tests | New integration tests for both flows |
