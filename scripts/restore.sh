#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Restore a backup from Cloudflare R2 → target Postgres database
#
# Usage (via entrypoint):
#   docker compose run --rm backup restore           # restores latest
#   docker compose run --rm backup restore backup-20260301-020012.sql.gz
#
# Required env vars:
#   TARGET_DB_URL       Fresh Render DB external URL (or any postgres URL)
#   R2_BUCKET, R2_ENDPOINT_URL, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY
#
# After restore, trigger a Render deploy to apply any pending migrations
# (Render runs `rails db:migrate` on every deploy automatically).
# ---------------------------------------------------------------------------

: "${TARGET_DB_URL:?TARGET_DB_URL must be set}"
: "${R2_BUCKET:?R2_BUCKET must be set}"
: "${R2_ENDPOINT_URL:?R2_ENDPOINT_URL must be set}"
: "${R2_ACCESS_KEY_ID:?R2_ACCESS_KEY_ID must be set}"
: "${R2_SECRET_ACCESS_KEY:?R2_SECRET_ACCESS_KEY must be set}"

export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID}"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY}"
export RCLONE_CONFIG_R2_ENDPOINT="${R2_ENDPOINT_URL}"
export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true

FILE_ARG="${1:-latest}"

if [[ "$FILE_ARG" == "latest" ]]; then
  FILENAME=$(rclone lsf "r2:${R2_BUCKET}/" | (grep 'backup-' || true) | sort | tail -1)
  if [[ -z "$FILENAME" ]]; then
    echo "[restore] Error: no backups found in r2:${R2_BUCKET}"
    exit 1
  fi
  echo "[restore] Latest backup: ${FILENAME}"
else
  FILENAME="$FILE_ARG"
fi

REDACTED_URL=$(echo "$TARGET_DB_URL" | sed 's|:[^:@]*@|:***@|')
echo "[restore] $(date -u) — restoring ${FILENAME} to ${REDACTED_URL} ..."

# Stream R2 → gunzip → psql (no temp file)
rclone cat "r2:${R2_BUCKET}/${FILENAME}" \
  | gunzip \
  | psql --set ON_ERROR_STOP=1 "${TARGET_DB_URL}"

echo ""
echo "[restore] Row counts:"
for TABLE in experiences recruiters users; do
  COUNT=$(psql "${TARGET_DB_URL}" -t -A -c "SELECT COUNT(*) FROM ${TABLE};")
  printf "  %-16s %s\n" "${TABLE}:" "${COUNT}"
done

echo ""
echo "[restore] Done. Next step: trigger a Render deploy to run pending migrations."
