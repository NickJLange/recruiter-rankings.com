## 1. Code Documentation
- [x] 1.1 Add deprecation notice to `web/app/models/review.rb` header — points to Interaction/Experience.
- [x] 1.2 Add deprecation notice to `web/app/models/review_metric.rb` header — clarifies belongs_to Experience, not Review.
- [x] 1.3 Add deprecation notice to `web/app/models/review_response.rb` header — notes migration needed to Experience.

## 2. Spec Documentation
- [x] 2.1 Create `openspec/changes/document-dual-data-model/specs/data-model-migration/spec.md` documenting:
  - Current state (two parallel models: Review vs Interaction/Experience)
  - Code path map (which controller uses which model)
  - ReviewMetric bug (belongs_to Experience but ReviewsController tries review.review_metrics)
  - 4-phase migration plan (fix bug → unify admin → migrate data → drop Review)
  - Prerequisites (all completed: test coverage, admin extraction, security hardening)

## 3. Project Context Update
- [x] 3.1 Updated `openspec/project.md` entities section with "Reviews (Deprecated)" and "ReviewResponse (Deprecated)" notation.
- [x] 3.2 Clarified ReviewMetric naming artifact (belongs_to Experience despite prefix).

## 4. Verification
- [x] 4.1 No code changes — documentation only (deprecation comments + spec + project.md).
- [x] 4.2 Deprecation notices are clear and actionable with pointers to the migration spec.
