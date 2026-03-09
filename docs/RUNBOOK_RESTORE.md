# Runbook: Database Restore

Estimated RTO: ~15 minutes for current database size.

R2 encrypts all stored objects at rest automatically (AES-256). No client-side encryption key is needed.

## Prerequisites

- `aws` CLI installed and configured (or environment variables set)
- `psql` installed (PostgreSQL client)
- Access to R2 credentials (see 1Password / GitHub Actions secrets)
- A target PostgreSQL database (local or remote — **never restore directly to production**)

Required environment variables:

```bash
export R2_BUCKET=recruiter-rankings-com-backups
export R2_ENDPOINT_URL=https://83ea2ae765d48de9f50ec024976dd319.r2.cloudflarestorage.com
export AWS_ACCESS_KEY_ID=<r2_access_key>
export AWS_SECRET_ACCESS_KEY=<r2_secret_key>
export AWS_DEFAULT_REGION=auto
```

---

## Step 1 — Find the latest backup

List all backups in R2, most recent last:

```bash
aws s3 ls "s3://${R2_BUCKET}/" \
  --endpoint-url "${R2_ENDPOINT_URL}" \
  | grep 'backup-' \
  | sort
```

Note the filename of the most recent backup, e.g. `backup-20260301-020012.sql.gz`.

---

## Step 2 — Create a target database (local restore)

```bash
createdb rr_restore_test
```

Or use an existing empty database. **Do not restore to your active development database** unless you intentionally want to overwrite it.

---

## Step 3 — Download and restore

Run the rake task (from `web/`):

```bash
rake 'db:backup:restore[backup-20260301-020012.sql.gz,postgres://localhost/rr_restore_test]'
```

Or manually:

```bash
aws s3 cp "s3://${R2_BUCKET}/backup-20260301-020012.sql.gz" - \
  --endpoint-url "${R2_ENDPOINT_URL}" \
  | gunzip \
  | psql postgres://localhost/rr_restore_test
```

---

## Step 4 — Verify row counts

```bash
psql postgres://localhost/rr_restore_test -c \
  "SELECT 'experiences' AS tbl, COUNT(*) FROM experiences
   UNION ALL SELECT 'recruiters', COUNT(*) FROM recruiters
   UNION ALL SELECT 'users',      COUNT(*) FROM users;"
```

Expected: all three counts > 0 and consistent with production.

---

## Step 5 — Smoke-test the app (optional but recommended)

```bash
DATABASE_URL=postgres://localhost/rr_restore_test \
  bundle exec rails runner "puts Recruiter.count; puts Experience.count"
```

---

## Recording the result

After completing a restore test, post a comment on the launch checklist issue noting:
- Date of restore test
- Backup file used
- Row counts from Step 4
- Any anomalies

---

## Automated monthly restore test

The `.github/workflows/backup.yml` workflow runs a restore test automatically on the 1st of each month (`0 3 1 * *` UTC). It:

1. Finds the latest backup in R2
2. Streams it directly into an ephemeral PostgreSQL container in GitHub Actions
3. Asserts row counts > 0 for experiences, recruiters, and users
4. Reports results in the GitHub Actions job summary

To trigger a manual restore test: go to Actions → "Database Backup & Maintenance" → Run workflow → check "Run restore test".
