## Context
The project supports multiple languages but requires a robust way to manage them without cluttering the main `master` branch or blocking English-centric development. We also need to manage large assets like embeddings efficiently.

## Goals / Non-Goals
- **Goals**:
  - Maintain a "Branch-per-Language" architecture.
  - Automate translation of missing keys using Gemini LLM.
  - Support manual overrides and spot-fixes on language branches.
  - Aggregated publishing: combine `master` (app code + EN) with language branches at release time.
  - Only fetch/update embeddings submodule during publishing.
- **Non-Goals**:
  - Continuous synchronization of all languages in the dev environment.

## Decisions
- **Architecture**: `master` branch contains the application and English locales. For each supported language `L`, a branch `lang-L` (e.g., `lang-ja`) contains the `L.yml` translation file.
- **Publishing Flow**:
  1. Checkout `master`.
  2. For each language `L` in `ALLOWED_LOCALES`:
     - Fetch/checkout `lang-L`.
     - Copy `L.yml` into `web/config/locales/` and `site/_data/i18n/`.
  3. Initialize and update `embeddings` submodule.
  4. Perform build/deploy.
- **Translation Workflow**:
  - Automated generation detects keys in `master:en.yml` not present in `lang-L:L.yml`.
  - Gemini LLM generates the missing values.
  - Result is committed to `lang-L`.
- **Spot Fixes**: Developers can check out `lang-L` directly, apply fixes, and commit. The generation service must use a merge strategy that respects existing keys.

## Risks / Trade-offs
- **Git Complexity**: Managing multiple long-lived branches requires careful orchestration.
- **Submodule State**: Ensuring the embeddings submodule is at the correct revision during publishing.
- **Merge Conflicts**: Automated generation must not overwrite manual spot-fixes.
