## Context
The Review model is deprecated in favor of Interaction/Experience, but both exist in the codebase with active code paths. The admin panel uses Review; the public API uses Interaction/Experience. This change documents the boundary so contributors know which model to use and why.

## Goals / Non-Goals
- **Goals**:
  - Make the deprecation explicit and visible in code and docs.
  - Document which code paths use which model.
  - Outline a future migration plan (without executing it).
- **Non-Goals**:
  - Migrating data or code (separate future change).
  - Removing the Review model or table.
  - Changing any runtime behavior.

## Decisions
- Add `# DEPRECATED` header to `review.rb` with pointer to Interaction/Experience.
- Document the two data paths clearly:
  - **Public write path**: ReviewsController#create → Interaction + Experience
  - **Public read path**: ReviewsController#index → Experience (joined with Interaction)
  - **Admin read path**: Admin::ReviewsController#index → Review
- Future migration (not this change): unify admin to read from Experience, migrate historical Review records, drop Review table.

## Risks / Trade-offs
- **None** — documentation-only change with no runtime impact.

## Migration Plan
- No data or code migration. Documentation only.
