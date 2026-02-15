# Change: Document Dual Data Model (Review vs Interaction/Experience)

## Why
The codebase has two parallel data models for reviews:
- **Legacy**: `Review` → `ReviewMetric` → `ReviewResponse`
- **Current**: `Interaction` → `Experience`

The public API writes to Interaction/Experience, but the admin panel reads from Review. This creates confusion about which model to use, risk of data inconsistency, and dead code paths. A full migration is premature without comprehensive test coverage (see `test-coverage-gaps` change), but the dual state should be explicitly documented so contributors don't accidentally extend the legacy model.

## What Changes
- **Documentation only**: No code changes.
- Add deprecation notice to `Review` model file header.
- Create an openspec spec documenting the data model state and migration plan.
- Update `openspec/project.md` to clarify Interaction/Experience as the current model.

## Impact
- **Modified Files**:
  - `web/app/models/review.rb` (add deprecation comment)
  - `openspec/project.md` (clarify current vs legacy entities)
- **New Files**:
  - `openspec/changes/document-dual-data-model/specs/data-model-migration/spec.md`
- **Affected Specs**: New `data-model-migration` spec
