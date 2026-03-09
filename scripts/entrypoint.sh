#!/usr/bin/env bash
set -e

# Make container env vars available to crond jobs (Alpine crond doesn't inherit env)
printenv | grep -v '^_=' > /etc/environment
chmod 600 /etc/environment

MODE="${1:-daemon}"

case "$MODE" in
  daemon)
    echo "[entrypoint] Starting backup daemon (cron)..."
    exec crond -f -l 2
    ;;
  backup)
    exec /app/backup.sh
    ;;
  restore)
    exec /app/restore.sh "${2:-latest}"
    ;;
  render-restore)
    exec /app/render-db-restore.sh
    ;;
  *)
    echo "Usage: entrypoint.sh [daemon|backup|restore [filename|latest]|render-restore]"
    exit 1
    ;;
esac
