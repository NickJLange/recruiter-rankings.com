# Proposal: Recruiter Profile Verification

## Status
Draft — 2026-02-21

## Dependency
Follows `integrate-clerk-auth`. The Clerk claim flow (LinkedIn OAuth) is implemented in that change. This change makes the verification model explicit and adds admin override controls that are needed regardless of which claim mechanism is used.

---

## Why This Change Is Needed

With real authenticated identities (Clerk), the platform enters a new risk regime: a person can be listed as a recruiter — with experiences attributed to them — before they have any opportunity to claim or dispute their profile. Today, the k-anonymity threshold (`PUBLIC_MIN_REVIEWS`, default 5) incidentally hides low-count profiles from public listings, but this is a side-effect of the privacy model, not an intentional verification mechanism.

Three specific gaps are left unaddressed by the existing code:

1. **No explicit "verified" state.** `recruiters.verified_at` exists in the schema and is set by `ClaimIdentityController#verify`, but it is never checked in `RecruitersController` or any public-facing query. A recruiter can be "verified" by the old token flow and still be invisible below threshold, or be visible above threshold without any verification. The states are unconnected.

2. **No admin override below threshold.** Once a recruiter's profile has a legitimate claim and an admin wants to surface it, there is no mechanism to do so short of lowering the global `PUBLIC_MIN_REVIEWS` env var — which affects all profiles.

3. **No audit trail for visibility decisions.** `ModerationAction` is already used for review state transitions (`set_status:approved`, etc.), but nothing logs when a profile becomes visible or is manually overridden.

---

## What This Change Does

### Explicit visibility model
Makes the k-anonymity threshold the canonical visibility rule, expressed in code rather than as an implicit query filter. A profile is **publicly visible** if either:
- It has ≥ k approved experiences from distinct authenticated users, OR
- An admin has granted a `visibility_override`

### Admin override mechanism
Adds a lightweight admin UI and controller action so a moderator can force-show a sub-threshold recruiter profile. This is the minimum viable intervention point — it does not change the k threshold globally, does not bypass the approved-experience requirement for full review access, and does not affect any other profile.

### Audit logging
Every `visibility_override` toggle is recorded as a `ModerationAction`, consistent with the existing moderation audit trail.

---

## What This Change Does NOT Do

- **Clerk-based claim flow rewrite** — the LinkedIn OAuth claim is part of `integrate-clerk-auth`
- **Remove or deprecate the token-challenge claim flow** — that is a separate cleanup decision
- **Right-of-reply or dispute mechanism** — out of scope
- **Change the k threshold value or make it per-recruiter** — `visibility_override` is a binary flag, not a threshold adjustment

---

## Impact Assessment

| Area | Impact |
|------|--------|
| Database | +1 column (`visibility_override boolean`) on `recruiters` table, non-null with default false |
| Public API | `GET /person` (recruiter index) query changes: `count >= k OR visibility_override` |
| Admin | New controller `Admin::RecruitersController`, new routes, new view |
| Audit trail | New `ModerationAction` records for toggle events |
| Existing tests | No existing tests cover the threshold filter directly; new tests cover both paths |
| Migrations | One migration, safe to run with zero downtime (adding nullable/defaulted column) |

---

## Alternatives Considered

**A. Use `verified_at` as the override signal** — Rejected. `verified_at` means "the recruiter has verified their identity via a challenge". Conflating identity verification with admin visibility override muddies both concepts. They should remain separate fields.

**B. Global threshold reduction via env var** — Rejected. Affects all profiles; not granular; requires a redeploy.

**C. Per-recruiter threshold** — Rejected. Over-engineered for the current need; adds complexity to query logic without clear benefit.
