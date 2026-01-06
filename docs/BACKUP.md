# Local Database Backup Guide

This guide describes how to set up daily backups of your Render Postgres database to your local laptop using a containerized approach.

## Retention Policy

The system uses a Grandfather-Father-Son (GFS) retention scheme:
- **Daily**: Keeps the last 7 days of backups.
- **Monthly**: Keeps the last 12 months (runs on the 1st of each month).
- **Yearly**: Keeps the last 2 years (runs on Jan 1st).

Backups are organized into `daily/`, `monthly/`, and `yearly/` subdirectories.

## Prerequisites

1.  **Docker or Podman**: Ensure you have a container engine installed.
2.  **External Database URL**: Obtain the **External Database URL** from the Render Dashboard.

## Setup

1.  **Configure Environment**:
    Create a file at `scripts/.env.local` (git-ignored):
    ```bash
    DATABASE_URL="postgres://user:pass@host.oregon-postgres.render.com/db_name"
    # Optional: override default backup directory
    # BACKUP_DIR="/app/backups" 
    ```

2.  **Build the Image**:
    ```bash
    cd scripts
    docker build -t rr-backup .
    ```

## Usage

### Run Manually (One-time)
You can run the backup manually via the container:
```bash
docker run --rm \
  --env-file scripts/.env.local \
  -v ~/Backups/recruiter-rankings:/app/backups \
  -e BACKUP_DIR=/app/backups \
  rr-backup /app/backup.sh
```

### Run as a Background Service
The container includes `cron` and is configured to run the backup daily at 2:00 AM.
```bash
docker run -d \
  --name rr-backup-service \
  --restart unless-stopped \
  --env-file scripts/.env.local \
  -v ~/Backups/recruiter-rankings:/app/backups \
  -e BACKUP_DIR=/app/backups \
  rr-backup
```

## Testing & Verification

You can verify the script's logic (directory creation, retention, rotations) without connecting to your real database by using the `MOCK_BACKUP` mode.

1.  **Run a dry-run test**:
    ```bash
    mkdir -p ~/Backups/test-run
    docker run --rm \
      -e MOCK_BACKUP=true \
      -e DATABASE_URL=dummy \
      -v ~/Backups/test-run:/app/backups \
      -e BACKUP_DIR=/app/backups \
      rr-backup /app/backup.sh
    ```
    This will create a dummy `.dump` file in `~/Backups/test-run/daily` without calling `pg_dump`.

## Security
- The `.env.local` file contains sensitive credentials and is git-ignored.
- Backups are stored on your local machine via volume mounts.
