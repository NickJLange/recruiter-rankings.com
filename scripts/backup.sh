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
DAILY_DIR="$BACKUP_DIR/daily"
MONTHLY_DIR="$BACKUP_DIR/monthly"
YEARLY_DIR="$BACKUP_DIR/yearly"

RETENTION_DAILY=7
RETENTION_MONTHLY=365
RETENTION_YEARLY=730

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DAY_OF_MONTH=$(date +%d)
MONTH_OF_YEAR=$(date +%m)
FILENAME="rr_prod_$TIMESTAMP.dump"
FILEPATH="$DAILY_DIR/$FILENAME"

# Create backup directories
mkdir -p "$DAILY_DIR" "$MONTHLY_DIR" "$YEARLY_DIR"

if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL is not set. Please provide it in $ENV_FILE or as an environment variable."
  exit 1
fi

echo "Starting backup of Render Postgres to $FILEPATH..."

# Run pg_dump
if pg_dump "$DATABASE_URL" -Fc -f "$FILEPATH"; then
  echo "Daily backup successful: $FILENAME"
  
  # Monthly rotation (1st of the month)
  if [ "$DAY_OF_MONTH" == "01" ]; then
    echo "Creating monthly backup..."
    cp "$FILEPATH" "$MONTHLY_DIR/rr_monthly_$TIMESTAMP.dump"
  fi

  # Yearly rotation (Jan 1st)
  if [ "$DAY_OF_MONTH" == "01" ] && [ "$MONTH_OF_YEAR" == "01" ]; then
    echo "Creating yearly backup..."
    cp "$FILEPATH" "$YEARLY_DIR/rr_yearly_$TIMESTAMP.dump"
  fi

  # Retention cleanup
  echo "Cleaning up old backups..."
  find "$DAILY_DIR" -name "rr_prod_*.dump" -mtime +$RETENTION_DAILY -delete
  find "$MONTHLY_DIR" -name "rr_monthly_*.dump" -mtime +$RETENTION_MONTHLY -delete
  find "$YEARLY_DIR" -name "rr_yearly_*.dump" -mtime +$RETENTION_YEARLY -delete
  echo "Cleanup complete."
else
  echo "Error: Backup failed!"
  exit 1
fi
