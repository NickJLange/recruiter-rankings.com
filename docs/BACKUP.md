# Database Backup & Restore

## Architecture

| Component | Role |
|-----------|------|
| **RPi4 container** (`scripts/`) | Primary backup daemon — runs daily at 2 AM, uploads to R2, pings healthchecks.io |
| **Cloudflare R2** | Durable backup store (AES-256 at rest, TLS in transit) |
| **GitHub Actions** (`backup.yml`) | Monthly independent restore test — downloads from R2, restores into CI postgres, asserts row counts |

---

## RPi4 Setup

### 1. Configure environment

```bash
cd scripts
cp .env.local.example .env.local
# Edit .env.local — fill in DATABASE_URL, R2_*, HEALTHCHECK_URL
```

### 2. Build and start the daemon

```bash
docker compose up -d --build
```

Backups run daily at 2 AM (container time). Logs stream to stdout — view with `docker compose logs -f`.

### 3. Verify the first backup

```bash
# Trigger a manual backup immediately
docker compose run --rm backup backup

# List what's in R2
docker compose run --rm backup backup  # check logs for "Uploaded to r2:..."
```

---

## Health monitoring

Set `HEALTHCHECK_URL` in `.env.local` to a [healthchecks.io](https://healthchecks.io) ping URL:

1. Sign up free at healthchecks.io
2. Create a check: **period = 1 day**, **grace = 2 hours**
3. Paste the ping URL into `.env.local`

If no backup succeeds within the grace period, healthchecks.io emails you.

---

## Render free-tier DB restore (every ~90 days)

The free Render PostgreSQL service is deleted after 90 days of inactivity. Run the automated restore script when that happens:

```bash
# Add RENDER_API_KEY, RENDER_OWNER_ID, RENDER_SERVICE_ID to .env.local first
docker compose run --rm backup render-restore
```

This does all five steps unattended:
1. Creates a new free PostgreSQL service on Render
2. Polls until it's available (~2 min) and extracts the External DB URL
3. Restores the latest R2 backup into it
4. Updates `DATABASE_URL` on your web service
5. Triggers a deploy (Render runs `db:migrate` automatically)

If the API doesn't return the External URL in time, the script pauses and asks you to paste it from the Render dashboard.

**Finding `RENDER_OWNER_ID` and `RENDER_SERVICE_ID`:**
- `RENDER_OWNER_ID`: Go to Render dashboard → click your avatar → the URL contains `usr-XXXX`
- `RENDER_SERVICE_ID`: Open your web service → the URL contains `srv-XXXX`

**Debug mode:** set `RENDER_DEBUG=1` to print raw API responses at each step.

---

## Manual restore procedure

Use this if you need to restore to a specific URL without the full Render automation:

```bash
# Restore latest backup to a specific DB
docker compose run --rm \
  -e TARGET_DB_URL="postgres://user:pass@host.render.com/dbname" \
  backup restore

# Restore a specific backup file
docker compose run --rm \
  -e TARGET_DB_URL="postgres://user:pass@host.render.com/dbname" \
  backup restore backup-20260301-020012.sql.gz
```

After restore, trigger a Render deploy manually — Render runs `db:migrate` automatically.

---

## Retention

Backups are kept for **30 days** (configurable via `RETENTION_DAYS`). Pruning runs automatically at the end of each backup job.

---

## GitHub Actions — monthly restore test

`.github/workflows/backup.yml` runs on the 1st of each month and via `workflow_dispatch`. It:

1. Downloads the latest backup from R2
2. Restores into an ephemeral CI postgres container
3. Asserts row counts > 0 for experiences, recruiters, and users

This is an independent check that R2 backups are actually restorable, separate from the RPi4.

---

## Rake task (local restore)

For local development restores without Docker:

```bash
cd web
rake 'db:backup:restore[backup-20260301-020012.sql.gz,postgres://localhost/rr_restore_test]'
```

Requires `aws` CLI (uses `R2_*` env vars from `web/.env`).

See `docs/RUNBOOK_RESTORE.md` for the full step-by-step procedure.
