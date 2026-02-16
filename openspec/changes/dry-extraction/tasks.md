## 1. Admin::BaseController
- [x] 1.1 Create `web/app/controllers/admin/base_controller.rb` with shared auth logic.
- [x] 1.2 Update `admin/reviews_controller.rb` to inherit from `Admin::BaseController`, remove duplicated methods.
- [x] 1.3 Update `admin/responses_controller.rb` to inherit from `Admin::BaseController`, remove duplicated methods.
- [x] 1.4 Update `admin/dashboard_controller.rb` to inherit from `Admin::BaseController`, remove duplicated methods.
- [x] 1.5 Add moderator identity caching (`@current_moderator_actor ||=`) to BaseController.
- [x] 1.6 Run `rails test` — admin tests pass (dashboard + reviews).

## 2. EmailIdentityService
- [x] 2.1 Create `web/app/services/email_identity_service.rb` with `hmac_email` and `find_or_create_user`.
- [x] 2.2 Update `reviews_controller.rb` to use `EmailIdentityService`, remove duplicated methods.
- [x] 2.3 `claim_identity_controller.rb` — no HMAC logic to remove (already clean after security-hardening).
- [x] 2.4 Add unit tests for `EmailIdentityService` (8 tests, all passing).
- [x] 2.5 Run `rails test` — review and claim tests pass.

## 3. Sluggable Concern
- [x] 3.1 Create `web/app/models/concerns/sluggable.rb`.
- [x] 3.2 Update `recruiter.rb` to include `Sluggable`, remove `generate_masked_slug` and confusing guard clause.
- [x] 3.3 Update `user.rb` to include `Sluggable`, remove `generate_masked_slug`.
- [x] 3.4 Run `rails test` — slug generation works correctly.

## 4. AccessControlHelper
- [x] 4.1 Create `web/app/helpers/access_control_helper.rb` with `can_view_details?`.
- [x] 4.2 Update `recruiters_controller.rb` to use helper, remove inline logic.
- [x] 4.3 Update `companies_controller.rb` to use helper, remove `can_view_details?` method and TODO.
- [x] 4.4 Include helper in `ApplicationController`, add to `helper_method` list.
- [x] 4.5 Run `rails test` — access control behavior unchanged.

## 5. Aggregate Model Scopes
- [x] 5.1 Add `approved_aggregates_by_recruiter` and `approved_aggregates_by_company` scopes to Experience model.
- [x] 5.2 Update `recruiters_controller.rb` to use scope instead of inline SQL.
- [x] 5.3 Update `companies_controller.rb` to use scopes instead of inline SQL (both index and show).
- [x] 5.4 Run `rails test` — aggregation results unchanged.

## 6. Final Verification
- [x] 6.1 Run full `rails test` suite — 83/102 pass (was 53/94 before this work).
- [x] 6.2 Verify no duplicated auth/HMAC/slug/access-control logic remains (grep confirms zero duplication).

## 7. Bonus: Pre-existing Issues Fixed
- [x] 7.1 Added missing `current_user` method to `ApplicationController` (was used everywhere but never defined). Fixed 23 pre-existing test failures.
