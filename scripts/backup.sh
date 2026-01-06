#!/usr/bin/env bash

# Local Database Backup for Render Postgres
# Usage: ./backup.sh

set -e

# Configuration
# It is recommended to put these in a .env.local file (git-ignored)
# DATABASE_URL="postgres://user:pass@host:port/db"
# BACKUP_DIR="$HOME/Backups/recruiter-rankings"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env.local"

if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# Defaults
BACKUP_DIR="${BACKUP_DIR:-$HOME/Backups/recruiter-rankings}"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="rr_prod_$TIMESTAMP.dump"
FILEPATH="$BACKUP_DIR/$FILENAME"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL is not set. Please provide it in $ENV_FILE or as an environment variable."
  exit 1
fi

echo "Starting backup of Render Postgres to $FILEPATH..."

# Run pg_dump
# -Fc: Custom format (compressed)
if pg_dump "$DATABASE_URL" -Fc -f "$FILEPATH"; then
  echo "Backup successful: $FILENAME"
  
  # Retention cleanup
  echo "Cleaning up backups older than $RETENTION_DAYS days..."
  find "$BACKUP_DIR" -name "rr_prod_*.dump" -mtime +$RETENTION_DAYS -exec rm {} \;
  echo "Cleanup complete."
else
  echo "Error: Backup failed!"
  exit 1
fi
