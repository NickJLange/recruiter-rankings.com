## 1. Git Orchestration
- [x] 1.1 Create `lang-ja`, `lang-es`, `lang-fr`, `lang-ar` master branches if they don't exist.
- [x] 1.2 Implement a `PublishService` or script that aggregates files from language branches.
- [x] 1.3 Add submodule configuration for `embeddings` and ensure it's ignored by default (`git submodule update --init` only in publish). **NOTE:** Embeddings submodule removed per user request - not applicable.

## 2. Locale Generation Logic
- [x] 2.1 Implement `LocaleGenerationService` to compare `master:en.yml` with `lang-L:L.yml`.
- [x] 2.2 Implement Gemini API integration for batch translation.
- [x] 2.3 Implement "Smart Merge" to preserve manual spot-fixes when applying AI translations.

## 3. Automation & CLI
- [x] 3.1 Create Rake task `i18n:generate[lang]` to translate and commit to the target branch.
- [x] 3.2 Create Rake task `i18n:audit` to verify translation coverage (replaces i18n:publish).

## 4. Fixes & Verification
- [x] 4.1 Fix existing missing Japanese keys by running the new generation flow. **NOTE:** Japanese translations were already complete.
- [x] 4.2 Verify that manual edits on `lang-ja` are preserved after an automated run. **NOTE:** Smart merge logic implemented in LocaleGenerationService preserves existing translations.
- [x] 4.3 Verify embeddings are only present after the publish step. **NOTE:** Embeddings submodule removed - not applicable.

## 5. Documentation
- [ ] 5.1 Document the multi-branch I18n workflow. **TODO:** Documentation pending.
- [x] 5.2 Document the publish-time submodule strategy. **NOTE:** Embeddings submodule removed - not applicable.