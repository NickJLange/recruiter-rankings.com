## 1. Code Documentation
- [ ] 1.1 Add deprecation notice to `web/app/models/review.rb` header — point to Interaction/Experience.
- [ ] 1.2 Add deprecation notice to `web/app/models/review_metric.rb` header.
- [ ] 1.3 Add deprecation notice to `web/app/models/review_response.rb` header (note: responses may need equivalent on Experience).

## 2. Spec Documentation
- [ ] 2.1 Create `openspec/changes/document-dual-data-model/specs/data-model-migration/spec.md` documenting:
  - Current state (two parallel models)
  - Which code paths use which model
  - Future migration plan (unify admin, migrate data, drop Review)
  - Prerequisites (test coverage, admin refactoring)

## 3. Project Context Update
- [ ] 3.1 Update `openspec/project.md` to clarify that Interaction/Experience is the current model and Review is deprecated.
- [ ] 3.2 Ensure `Reviews (Deprecated)` notation is clear in the entities section.

## 4. Verification
- [ ] 4.1 Verify no code changes — documentation only.
- [ ] 4.2 Review that deprecation notices are clear and actionable.
