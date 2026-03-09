## Context
The application requires a disaster recovery mechanism. As a privacy-focused platform, maintaining data integrity and availability is critical. We need a solution that runs automatically but respects the budget constraints (Render free tier, minimal storage costs).

## Goals / Non-Goals
- **Goals**:
  - Automate PostgreSQL backups.
  - Secure backups at rest (Encryption).
  - Support generic S3-compatible storage (e.g., AWS S3, Cloudflare R2, MinIO) and Local storage.
  - Configurable retention (keep last X days, Y weeks).
- **Non-Goals**:
  - Real-time replication or Point-in-Time Recovery (PITR) (Managed PG offers some, but this is off-site archival).
  - Complex UI for backup management (CLI/Rake is sufficient).

## Decisions
- **Tooling**: Use standard `pg_dump` mapped to `gzip`.
- **Render Integration**: Implement a `RenderApiClient` to authenticate via API Key and fetch database details (Endpoint, Name) directly from the Render API. This provides a robust way to discover connection details and metadata beyond static configuration.
- **Encryption**: Use Rails `ActiveSupport::MessageEncryptor` or standard AES-256 tools before upload to ensure the file is encrypted *before* leaving the app context.
- **Storage**: Use `ActiveStorage` or a lightweight wrapper around `aws-sdk-s3` to avoid heavy dependencies if possible. Given the specific requirement for "S3-compatible", a direct service object using `aws-sdk-s3` is standard and reliable.
- **Scheduling**: Since we are on Render (PaaS), standard cron might be tricky if not using a specific scheduler service. We will expose a Rake task that can be triggered via Render's "Cron Job" service or a simple scheduler within the app if a worker process is running.

## Risks / Trade-offs
- **Memory**: processing large dumps in memory is dangerous. We must stream data: `pg_dump | gzip | openssl > temp_file` then stream upload.
- **Disk Space**: The ephemeral disk on Render might fill up if the DB is huge. We should stream directly to remote storage if possible, or ensure we clean up strictly.

## Migration Plan
- N/A - New feature.
