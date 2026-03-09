# Change: Add Locale Generation & Multi-Branch Publishing

## Why
Maintaining manual translations across multiple languages is error-prone. To ensure high-quality, localized content while allowing the main development to move fast, we need a system that segregates languages into their own branches and automates the translation and synchronization process. This also applies to heavy assets like embeddings, which should only be fetched during the publishing phase to keep the main repository lean.

## What Changes
- **Branching Strategy**: Each language (ja, es, fr, etc.) lives on its own master branch (e.g., `lang-ja`).
- **New Service**: `LocaleGenerationService` to identify missing keys in `master` (English) and generate translations via LLM for the target language branches.
- **Aggregation Logic**: A publishing script that pulls language-specific files from their respective branches into the final build.
- **Embeddings Integration**: Embeddings managed as a submodule, initialized and updated only during the publishing phase.
- **Manual Fixes**: Support for manual "spot fixes" on language branches that persist across automated generation cycles.

## Impact
- **Affected Specs**: `i18n-management`
- **Affected Code**:
  - `web/app/services/locale_generation_service.rb`
  - `web/lib/tasks/i18n.rake`
  - `scripts/publish.sh` (New)
  - Git configuration (Submodules, Branches)