## 1. Admin::BaseController
- [ ] 1.1 Create `web/app/controllers/admin/base_controller.rb` with shared auth logic.
- [ ] 1.2 Update `admin/reviews_controller.rb` to inherit from `Admin::BaseController`, remove duplicated methods.
- [ ] 1.3 Update `admin/responses_controller.rb` to inherit from `Admin::BaseController`, remove duplicated methods.
- [ ] 1.4 Update `admin/dashboard_controller.rb` to inherit from `Admin::BaseController`, remove duplicated methods.
- [ ] 1.5 Add moderator identity (user ID) to ModerationAction records.
- [ ] 1.6 Run `rails test` — verify all admin tests pass.

## 2. EmailIdentityService
- [ ] 2.1 Create `web/app/services/email_identity_service.rb` with `hmac_email` and `find_or_create_user`.
- [ ] 2.2 Update `reviews_controller.rb` to use `EmailIdentityService`, remove duplicated methods.
- [ ] 2.3 Update `claim_identity_controller.rb` to use `EmailIdentityService`, remove duplicated methods.
- [ ] 2.4 Add unit tests for `EmailIdentityService`.
- [ ] 2.5 Run `rails test` — verify all review and claim tests pass.

## 3. Sluggable Concern
- [ ] 3.1 Create `web/app/models/concerns/sluggable.rb`.
- [ ] 3.2 Update `recruiter.rb` to include `Sluggable`, remove `generate_masked_slug` and confusing guard clause.
- [ ] 3.3 Update `user.rb` to include `Sluggable`, remove `generate_masked_slug`.
- [ ] 3.4 Run `rails test` — verify slug generation tests pass.

## 4. AccessControlHelper
- [ ] 4.1 Create `web/app/helpers/access_control_helper.rb` with `can_view_details?`.
- [ ] 4.2 Update `recruiters_controller.rb` to use helper, remove inline logic.
- [ ] 4.3 Update `companies_controller.rb` to use helper, remove `can_view_details?` method and TODO.
- [ ] 4.4 Run `rails test` — verify access control behavior unchanged.

## 5. Aggregate Model Scopes
- [ ] 5.1 Add `approved_aggregates_by_recruiter` scope to Experience model.
- [ ] 5.2 Update `recruiters_controller.rb` to use scope instead of inline SQL.
- [ ] 5.3 Update `companies_controller.rb` to use scope instead of inline SQL.
- [ ] 5.4 Run `rails test` — verify aggregation results unchanged.

## 6. Final Verification
- [ ] 6.1 Run full `rails test` suite.
- [ ] 6.2 Verify no duplicated auth/HMAC/slug/access-control logic remains (grep).
