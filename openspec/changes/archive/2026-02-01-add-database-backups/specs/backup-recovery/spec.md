## ADDED Requirements

### Requirement: Automated Database Backups
The system SHALL support automated, scheduled backups of the primary PostgreSQL database.

#### Scenario: Scheduled Execution
- **WHEN** the scheduled time arrives (e.g., daily at 02:00 UTC)
- **THEN** a backup job is enqueued
- **AND** a compressed SQL dump is generated
- **AND** the dump is encrypted
- **AND** the dump is uploaded to the configured storage provider
- **AND** old backups exceeding the retention policy are deleted

### Requirement: Manual Backup Trigger
The system SHALL provide a command-line interface (Rake task) to trigger an immediate backup.

#### Scenario: Manual Invocation
- **WHEN** an admin runs `rake db:backup:create`
- **THEN** a backup is performed immediately
- **AND** output is logged to stdout

### Requirement: Backup Encryption
All backup artifacts SHALL be encrypted at rest using a dedicated encryption key.

#### Scenario: Encryption Validation
- **WHEN** a backup file is inspected on the storage provider
- **THEN** the content is unreadable without the decryption key

### Requirement: Retention Policy
The system SHALL enforce a configurable retention policy to minimize storage usage.

#### Scenario: Pruning Old Backups
- **GIVEN** a retention policy of "keep 7 days"
- **WHEN** a new backup completes successfully
- **THEN** any backups older than 7 days are deleted from storage

### Requirement: Backup Notifications
The system SHALL notify administrators upon backup success or failure.

#### Scenario: Failure Notification
- **WHEN** a backup job fails (e.g., due to storage connection error)
- **THEN** an email alert is sent to the configured admin email address containing the error details
