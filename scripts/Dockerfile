FROM alpine:3.18

# rclone: R2 upload/download (arm64-compatible via apk)
# postgresql15-client: pg_dump + psql
# curl: healthchecks.io ping
RUN apk add --no-cache \
    bash \
    postgresql15-client \
    curl \
    coreutils \
    rclone \
    jq

WORKDIR /app

COPY entrypoint.sh backup.sh restore.sh render-db-restore.sh ./
COPY crontab /etc/crontabs/root

RUN chmod +x entrypoint.sh backup.sh restore.sh render-db-restore.sh

# daemon          → runs crond (default)
# backup          → one-shot backup
# restore         → restore [filename|latest]
# render-restore  → full Render free-DB lifecycle restore (create → restore → deploy)
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["daemon"]
