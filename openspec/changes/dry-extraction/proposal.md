# Change: DRY Extraction — Consolidate Duplicated Logic

## Why
Code review identified five areas where logic is copy-pasted across multiple files. Each duplication means bug fixes and security patches must be applied in multiple places, increasing the risk of inconsistency. These extractions follow standard Rails patterns (concerns, services, helpers) and reduce total code while improving testability.

## What Changes
- **Admin::BaseController**: Extract duplicated moderator auth from 3 admin controllers into a shared base controller. Add moderator identity tracking to ModerationAction.
- **EmailIdentityService**: Extract duplicated `hmac_email` and `find_or_create_user` from 2 controllers into a dedicated service.
- **Sluggable concern**: Extract duplicated `generate_masked_slug` from Recruiter and User models into a shared concern. Fix confusing guard clause in Recruiter version.
- **AccessControlHelper**: Unify inconsistent `can_view_details?` logic between RecruitersController and CompaniesController. Complete the TODO for company ownership checks.
- **Model scopes for aggregates**: Extract inline SQL subqueries from RecruitersController and CompaniesController into model scopes.

## Impact
- **Affected Code**:
  - `web/app/controllers/admin/` (3 controllers → 1 base + 3 inheriting)
  - `web/app/controllers/reviews_controller.rb` (remove HMAC methods)
  - `web/app/controllers/claim_identity_controller.rb` (remove HMAC methods)
  - `web/app/controllers/recruiters_controller.rb` (use scopes + helper)
  - `web/app/controllers/companies_controller.rb` (use scopes + helper)
  - `web/app/models/recruiter.rb` (use Sluggable concern)
  - `web/app/models/user.rb` (use Sluggable concern)
  - `web/app/models/experience.rb` (add aggregate scopes)
- **New Files**:
  - `web/app/controllers/admin/base_controller.rb`
  - `web/app/services/email_identity_service.rb`
  - `web/app/models/concerns/sluggable.rb`
  - `web/app/helpers/access_control_helper.rb`
- **Affected Specs**: None (no spec changes)
