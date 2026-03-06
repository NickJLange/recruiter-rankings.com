# Data Retention Policy

This document describes what user data is retained, what is cleaned up, and when.

See `gameplan.md` for the product-level privacy rationale.

---

## What is cleaned up automatically

### Expired identity challenges

**Table**: `identity_challenges`
**Condition**: `expires_at < NOW() AND verified_at IS NULL`
**Schedule**: Daily, immediately after the backup (2 AM UTC via `backup.yml`)
**Rake task**: `rake data:retention:cleanup`

Identity challenges are short-lived tokens issued during the email-verification flow. A challenge that has expired without being verified is safe to delete — the user would need to re-verify if they want to proceed.

Verified challenges (`verified_at IS NOT NULL`) are retained indefinitely as audit evidence.

---

## What is retained indefinitely

| Data | Reason |
|------|--------|
| `experiences` (review bodies) | Core product — the recruiter reviews themselves |
| `recruiters` | Directory entries |
| `users` | Account records |
| `interactions` | Linked to experiences |
| Verified `identity_challenges` | Audit trail of identity verification |

Review text (`experiences.body`) is the product and is never auto-deleted. Users who want their review removed can submit a takedown request.

---

## What is NOT stored (no cleanup needed)

Per `gameplan.md`, the following are intentionally not persisted to the database:

- IP addresses
- User agents / browser fingerprints
- Session metadata beyond what Clerk manages

Because these are not stored in the app database, no database cleanup job is needed for them. Clerk's own data retention applies to auth-side logs.

---

## Running the cleanup manually

```bash
cd web
bundle exec rake data:retention:cleanup
```

Output: `Deleted N expired, unverified identity challenge(s).`

---

## GDPR / Privacy compliance notes

- The 180-day data minimisation clock in `gameplan.md` applies to user metadata (IP, user-agent). These are not stored in the app DB, so no additional cleanup is needed at launch.
- Review content is retained as a legitimate interest (public accountability for recruiters). Users may request deletion via the takedown flow.
- Identity challenge tokens are stored as bcrypt hashes (`token_hash`), never in plaintext.
