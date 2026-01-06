# Local Database Backup Guide

This guide describes how to set up daily backups of your Render Postgres database to your local laptop.

## Prerequisites

1.  **PostgreSQL Client**: Ensure you have `pg_dump` installed locally.
    - macOS (Homebrew): `brew install postgresql` or `brew install libpq`
2.  **External Database URL**: Obtain the **External Database URL** from the Render Dashboard (Postgres instance -> Connect -> External Database URL).

## Setup

1.  **Configure Environment**:
    Create a file at `scripts/.env.local` (this file is git-ignored) and add your connection string:
    ```bash
    DATABASE_URL="postgres://user:pass@host.oregon-postgres.render.com/db_name"
    # Optional: override default backup directory
    # BACKUP_DIR="/path/to/your/backups"
    ```

2.  **Make Script Executable**:
    ```bash
    chmod +x scripts/backup.sh
    ```

## Usage

Run the backup manually:
```bash
./scripts/backup.sh
```

The script will:
- Create the backup directory if it doesn't exist (default: `~/Backups/recruiter-rankings`).
- Create a compressed `.dump` file with a timestamp.
- Delete backups older than 7 days.

## Automation (Optional)

### macOS (launchd)

To automate this daily on macOS, you can create a `launchd` plist file.

1.  Create `~/Library/LaunchAgents/com.recruiter-rankings.backup.plist`:
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.recruiter-rankings.backup</string>
        <key>ProgramArguments</key>
        <array>
            <string>/Users/your-username/dev/src/recruiter-rankings.com/scripts/backup.sh</string>
        </array>
        <key>StartCalendarInterval</key>
        <dict>
            <key>Hour</key>
            <integer>2</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
    </dict>
    </plist>
    ```
2.  Load the agent:
    ```bash
    launchctl load ~/Library/LaunchAgents/com.recruiter-rankings.backup.plist
    ```
