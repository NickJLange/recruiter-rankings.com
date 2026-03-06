#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Backup Render Postgres → Cloudflare R2
# ---------------------------------------------------------------------------
# Required env vars:
#   DATABASE_URL        Render external connection string
#   R2_BUCKET           Cloudflare R2 bucket name
#   R2_ENDPOINT_URL     https://<accountid>.r2.cloudflarestorage.com
#   R2_ACCESS_KEY_ID    R2 API token access key
#   R2_SECRET_ACCESS_KEY
#
# Optional:
#   RETENTION_DAYS      Prune backups older than N days (default: 30)
#   HEALTHCHECK_URL     healthchecks.io ping URL — notifies on failure too
# ---------------------------------------------------------------------------

: "${DATABASE_URL:?DATABASE_URL must be set}"
: "${R2_BUCKET:?R2_BUCKET must be set}"
: "${R2_ENDPOINT_URL:?R2_ENDPOINT_URL must be set}"
: "${R2_ACCESS_KEY_ID:?R2_ACCESS_KEY_ID must be set}"
: "${R2_SECRET_ACCESS_KEY:?R2_SECRET_ACCESS_KEY must be set}"

RETENTION_DAYS="${RETENTION_DAYS:-30}"

# Configure rclone via env (no config file needed)
export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID}"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY}"
export RCLONE_CONFIG_R2_ENDPOINT="${R2_ENDPOINT_URL}"
export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true

# Ping healthchecks.io (start signal; /start suffix marks job begun)
if [[ -n "${HEALTHCHECK_URL:-}" ]]; then
  curl -fsS --retry 3 --max-time 10 "${HEALTHCHECK_URL}/start" || true
fi

TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
FILENAME="backup-${TIMESTAMP}.sql.gz"

echo "[backup] $(date -u) — creating ${FILENAME} ..."

# Stream pg_dump → gzip → R2 (no temp file)
pg_dump "${DATABASE_URL}" \
  --no-owner --no-acl -Fp \
  | gzip \
  | rclone rcat "r2:${R2_BUCKET}/${FILENAME}"

echo "[backup] Uploaded to r2:${R2_BUCKET}/${FILENAME}"

# ---------------------------------------------------------------------------
# Retention: delete backups older than RETENTION_DAYS
# ---------------------------------------------------------------------------
CUTOFF=$(date -u -d "${RETENTION_DAYS} days ago" +%Y%m%d)
REMOVED=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  FILEDATE=$(echo "$file" | grep -oP '(?<=backup-)\d{8}' || true)
  if [[ -n "$FILEDATE" && "$FILEDATE" < "$CUTOFF" ]]; then
    rclone deletefile "r2:${R2_BUCKET}/${file}"
    REMOVED=$((REMOVED + 1))
    echo "[backup] Pruned ${file}"
  fi
done < <(rclone lsf "r2:${R2_BUCKET}/")

echo "[backup] Pruned ${REMOVED} backup(s) older than ${RETENTION_DAYS} days"

# Ping healthchecks.io — success
if [[ -n "${HEALTHCHECK_URL:-}" ]]; then
  curl -fsS --retry 3 --max-time 10 "${HEALTHCHECK_URL}" || true
fi

echo "[backup] Done."
