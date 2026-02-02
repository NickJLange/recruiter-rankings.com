## 1. Git Orchestration
- [ ] 1.1 Create `lang-ja`, `lang-es`, `lang-fr` master branches if they don't exist.
- [ ] 1.2 Implement a `PublishService` or script that aggregates files from language branches.
- [ ] 1.3 Add submodule configuration for `embeddings` and ensure it's ignored by default (`git submodule update --init` only in publish).

## 2. Locale Generation Logic
- [ ] 2.1 Implement `LocaleGenerationService` to compare `master:en.yml` with `lang-L:L.yml`.
- [ ] 2.2 Implement Gemini API integration for batch translation.
- [ ] 2.3 Implement "Smart Merge" to preserve manual spot-fixes when applying AI translations.

## 3. Automation & CLI
- [ ] 3.1 Create Rake task `i18n:generate[lang]` to translate and commit to the target branch.
- [ ] 3.2 Create Rake task `i18n:publish` to aggregate all languages and embeddings for a release.

## 4. Fixes & Verification
- [ ] 4.1 Fix existing missing Japanese keys by running the new generation flow.
- [ ] 4.2 Verify that manual edits on `lang-ja` are preserved after an automated run.
- [ ] 4.3 Verify embeddings are only present after the publish step.

## 5. Documentation
- [ ] 5.1 Document the multi-branch I18n workflow.
- [ ] 5.2 Document the publish-time submodule strategy.