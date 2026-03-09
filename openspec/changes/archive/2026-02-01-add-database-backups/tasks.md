## 1. Core Implementation
- [x] 1.1 Implement `RenderApiClient` to fetch database connection details (Endpoint, Name) using API Key.
- [x] 1.2 Create `BackupService` skeleton with adapter pattern for storage.
- [x] 1.3 Implement `PgDump` wrapper to generate compressed SQL dumps.
- [x] 1.4 Implement Encryption layer (e.g., ActiveSupport::MessageEncryptor or GPG).
- [x] 1.5 Implement Storage Adapters (LocalDisk, S3).
- [x] 1.6 Implement Retention Policy logic (pruning old backups).

## 2. Integration & scheduling
- [x] 2.1 Create `ScheduledBackupJob` using ActiveJob/Sidekiq (or whatever queue system is in use).
- [x] 2.2 Add Rake task `db:backup:create` and `db:backup:restore`.
- [x] 2.3 Configure `scheduler` (e.g., whenever gem or sidekiq-scheduler) if not present, or document cron usage.

## 3. Notifications
- [x] 3.1 Create `BackupMailer` for success/failure notifications.
- [x] 3.2 Trigger mailer from `BackupService`.

## 4. Testing & Documentation

- [x] 4.1 Write Unit Tests for `BackupService` and Retention logic.

- [x] 4.2 Write Integration Tests for the full backup flow (mocking S3).

- [x] 4.3 Update `README.md` with configuration and restore instructions.

- [x] 4.4 Update `DATABASE_SETUP.md` with disaster recovery procedures.
