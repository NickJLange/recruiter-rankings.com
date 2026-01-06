FROM alpine:3.18

# Install dependencies
RUN apk add --no-cache \
    bash \
    postgresql15-client \
    curl \
    grep \
    coreutils

# Create backup directory
WORKDIR /app

# Copy the backup script
COPY backup.sh .
COPY crontab /etc/crontabs/root

RUN chmod +x backup.sh

# Run cron in foreground
CMD ["crond", "-f", "-l", "2"]
