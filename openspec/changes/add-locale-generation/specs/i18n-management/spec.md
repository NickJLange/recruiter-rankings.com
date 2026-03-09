## ADDED Requirements

### Requirement: Branch-per-Language Isolation
The system SHALL maintain translation files for each non-primary language on its own dedicated master branch.

#### Scenario: Segregated locales
- **WHEN** the `master` branch is updated with new English keys
- **THEN** the `lang-ja` branch remains unchanged until an explicit synchronization or generation step occurs.

### Requirement: Publishing-time Aggregation
The system SHALL aggregate translation files from all language-specific branches and the embeddings submodule during the publishing/release process.

#### Scenario: Cutting a release
- **WHEN** the `i18n:publish` task is executed
- **THEN** the system pulls the latest `ja.yml` from `lang-ja`, `es.yml` from `lang-es`, etc.
- **AND** it initializes the `embeddings` submodule
- **AND** it places all assets in the correct locations for the build.

### Requirement: Preservation of Manual Spot-Fixes
The automated translation process SHALL NOT overwrite manual adjustments made to language-specific translation files.

#### Scenario: AI translation vs Manual fix
- **GIVEN** a manual fix has been applied to a key in `lang-ja:ja.yml`
- **WHEN** automated generation is run for missing keys
- **THEN** the manual fix is preserved
- **AND** only actually missing keys are added or updated if they haven't been manually tuned.

### Requirement: Lazy Embeddings Submodule
The `embeddings` submodule SHALL be initialized and updated only during the publishing phase.

#### Scenario: Clean development environment
- **GIVEN** a standard `git clone` or `git pull` on `master`
- **THEN** the `embeddings` directory remains empty or uninitialized to save space and bandwidth.