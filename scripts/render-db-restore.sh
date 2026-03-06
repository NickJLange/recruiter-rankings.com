#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# render-db-restore.sh
#
# Full Render free-tier DB lifecycle restore:
#   1. Create a new Render PostgreSQL (free) service
#   2. Poll until available, extract External Connection URL
#   3. Restore latest (or named) R2 backup into it
#   4. Update the web service DATABASE_URL env var
#   5. Trigger a Render deploy (which runs db:migrate automatically)
#
# Required env vars:
#   RENDER_API_KEY      Render Dashboard → Account Settings → API Keys
#   RENDER_OWNER_ID     Your user ID — visible in the Render dashboard URL,
#                       e.g. https://dashboard.render.com/u/usr-XXXX → "usr-XXXX"
#   RENDER_SERVICE_ID   Web service ID — visible in the service URL on Render,
#                       e.g. https://dashboard.render.com/web/srv-XXXX → "srv-XXXX"
#   R2_BUCKET, R2_ENDPOINT_URL, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY
#
# Optional:
#   RENDER_REGION       Region for new DB (default: oregon)
#   RESTORE_FILE        Specific backup filename (default: latest)
#   RENDER_DEBUG=1      Print raw API responses
# ---------------------------------------------------------------------------

RENDER_API="https://api.render.com/v1"
RENDER_REGION="${RENDER_REGION:-oregon}"
RESTORE_FILE="${RESTORE_FILE:-latest}"

: "${RENDER_API_KEY:?RENDER_API_KEY must be set}"
: "${RENDER_OWNER_ID:?RENDER_OWNER_ID must be set}"
: "${RENDER_SERVICE_ID:?RENDER_SERVICE_ID must be set}"
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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

render_get() {
  local path="$1"
  local response
  response=$(curl -fsS \
    -H "Authorization: Bearer ${RENDER_API_KEY}" \
    -H "Accept: application/json" \
    "${RENDER_API}${path}")
  [[ "${RENDER_DEBUG:-}" == "1" ]] && echo "[debug GET ${path}] ${response}" >&2
  echo "$response"
}

render_post() {
  local path="$1"
  local body="${2:-{\}}"
  local response
  response=$(curl -fsS -X POST \
    -H "Authorization: Bearer ${RENDER_API_KEY}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "${RENDER_API}${path}")
  [[ "${RENDER_DEBUG:-}" == "1" ]] && echo "[debug POST ${path}] ${response}" >&2
  echo "$response"
}

render_put() {
  local path="$1"
  local body="$2"
  local response
  response=$(curl -fsS -X PUT \
    -H "Authorization: Bearer ${RENDER_API_KEY}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "${RENDER_API}${path}")
  [[ "${RENDER_DEBUG:-}" == "1" ]] && echo "[debug PUT ${path}] ${response}" >&2
  echo "$response"
}

redact() { echo "$1" | sed 's|:[^:@/]*@|:***@|g'; }

# ---------------------------------------------------------------------------
# Step 1: Create new PostgreSQL service
# ---------------------------------------------------------------------------
echo ""
echo "=== [1/5] Creating Render PostgreSQL (free / ${RENDER_REGION}) ==="

CREATE_BODY=$(jq -n \
  --arg name       "recruiter-rankings-db" \
  --arg dbName     "rr_prod" \
  --arg dbUser     "rr_user" \
  --arg ownerId    "${RENDER_OWNER_ID}" \
  --arg region     "${RENDER_REGION}" \
  '{
    name: $name,
    databaseName: $dbName,
    databaseUser: $dbUser,
    ownerId: $ownerId,
    region: $region,
    plan: "free",
    enableHighAvailability: false
  }')

NEW_DB=$(render_post "/postgres" "$CREATE_BODY")
NEW_DB_ID=$(echo "$NEW_DB" | jq -r '.id // empty')

if [[ -z "$NEW_DB_ID" ]]; then
  echo "ERROR: Could not create PostgreSQL service. Raw response:"
  echo "$NEW_DB"
  exit 1
fi

echo "Created service: ${NEW_DB_ID}"

# ---------------------------------------------------------------------------
# Step 2: Poll until available
# ---------------------------------------------------------------------------
echo ""
echo "=== [2/5] Waiting for DB to become available (up to 5 min) ==="

MAX_WAIT=300
ELAPSED=0
EXTERNAL_URL=""

while [[ $ELAPSED -lt $MAX_WAIT ]]; do
  DB_INFO=$(render_get "/postgres/${NEW_DB_ID}")
  STATUS=$(echo "$DB_INFO"    | jq -r '.status // "unknown"')
  EXTERNAL_URL=$(echo "$DB_INFO" | jq -r '.connectionInfo.externalConnectionString // empty')

  printf "  %3ds  status: %s\n" "$ELAPSED" "$STATUS"

  if [[ "$STATUS" == "available" && -n "$EXTERNAL_URL" ]]; then
    break
  fi

  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

if [[ -z "$EXTERNAL_URL" ]]; then
  echo ""
  echo "DB did not become available automatically within ${MAX_WAIT}s."
  echo "Find the External Database URL in the Render dashboard and paste it here:"
  read -r -p "External Database URL: " EXTERNAL_URL
fi

echo "DB ready: $(redact "$EXTERNAL_URL")"

# ---------------------------------------------------------------------------
# Step 3: Restore backup
# ---------------------------------------------------------------------------
echo ""
echo "=== [3/5] Restoring backup ==="

if [[ "$RESTORE_FILE" == "latest" ]]; then
  RESTORE_FILE=$(rclone lsf "r2:${R2_BUCKET}/" | grep 'backup-' | sort | tail -1)
  if [[ -z "$RESTORE_FILE" ]]; then
    echo "ERROR: no backups found in r2:${R2_BUCKET}"
    exit 1
  fi
fi

echo "File: ${RESTORE_FILE}"

rclone cat "r2:${R2_BUCKET}/${RESTORE_FILE}" \
  | gunzip \
  | psql "${EXTERNAL_URL}"

echo ""
echo "Row counts post-restore:"
for TABLE in experiences recruiters users; do
  COUNT=$(psql "${EXTERNAL_URL}" -t -A -c "SELECT COUNT(*) FROM ${TABLE};")
  printf "  %-16s %s\n" "${TABLE}:" "${COUNT}"
done

# ---------------------------------------------------------------------------
# Step 4: Update DATABASE_URL on web service
# ---------------------------------------------------------------------------
echo ""
echo "=== [4/5] Updating DATABASE_URL on service ${RENDER_SERVICE_ID} ==="

CURRENT_VARS=$(render_get "/services/${RENDER_SERVICE_ID}/env-vars")

# Rebuild env var list with updated DATABASE_URL; strip any extra API fields
DB_URL_EXISTS=$(echo "$CURRENT_VARS" | jq '[.[] | select(.key == "DATABASE_URL")] | length')

if [[ "$DB_URL_EXISTS" -gt 0 ]]; then
  UPDATED_VARS=$(echo "$CURRENT_VARS" | jq \
    --arg url "$EXTERNAL_URL" \
    '[.[] | {key: .key, value: (if .key == "DATABASE_URL" then $url else .value end)}]')
else
  # DATABASE_URL not yet present — append it
  UPDATED_VARS=$(echo "$CURRENT_VARS" | jq \
    --arg url "$EXTERNAL_URL" \
    '[.[] | {key: .key, value: .value}] + [{key: "DATABASE_URL", value: $url}]')
fi

render_put "/services/${RENDER_SERVICE_ID}/env-vars" "$UPDATED_VARS" > /dev/null
echo "DATABASE_URL updated to: $(redact "$EXTERNAL_URL")"

# ---------------------------------------------------------------------------
# Step 5: Trigger deploy (runs db:migrate)
# ---------------------------------------------------------------------------
echo ""
echo "=== [5/5] Triggering Render deploy ==="

DEPLOY=$(render_post "/services/${RENDER_SERVICE_ID}/deploys" '{"clearCache":"do_not_clear"}')
DEPLOY_ID=$(echo "$DEPLOY" | jq -r '.id // empty')

if [[ -n "$DEPLOY_ID" ]]; then
  echo "Deploy triggered: ${DEPLOY_ID}"
  echo "Monitor: https://dashboard.render.com/web/${RENDER_SERVICE_ID}/deploys/${DEPLOY_ID}"
else
  echo "Could not confirm deploy trigger — check Render dashboard."
  [[ "${RENDER_DEBUG:-}" == "1" ]] && echo "$DEPLOY"
fi

echo ""
echo "=== All done ==="
echo "The app will be live once the deploy finishes (~2 min)."
echo "Render will run 'bundle exec rails db:migrate' automatically."
