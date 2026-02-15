## Context
A BIG CHANGE code review identified five DRY violations where identical or near-identical logic is duplicated across files. Each extraction follows a standard Rails pattern and reduces maintenance burden.

## Goals / Non-Goals
- **Goals**:
  - Eliminate all identified copy-paste duplication.
  - Improve testability by isolating logic into dedicated units.
  - Complete the unfinished TODO for company access control.
  - Fix the confusing guard clause in Recruiter slug generation.
- **Non-Goals**:
  - Changing business logic or behavior (pure refactoring).
  - Adding caching to aggregate queries (separate concern).
  - Migrating away from HTTP Basic Auth (separate change).

## Decisions

### 1. Admin::BaseController
```ruby
# web/app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
  before_action :require_moderator_auth

  private

  def require_moderator_auth
    expected_user = ENV["DEMO_MOD_USER"].presence || "mod"
    expected_pass = ENV["DEMO_MOD_PASSWORD"].presence || "mod"
    authenticate_or_request_with_http_basic("Moderation") do |u, p|
      ActiveSupport::SecurityUtils.secure_compare(u, expected_user) &&
        ActiveSupport::SecurityUtils.secure_compare(p, expected_pass)
    end
  end

  def current_moderator_actor
    @current_moderator_actor ||= User.find_by(role: "moderator")
  end
end
```
All three admin controllers inherit from this. Delete duplicated methods.

### 2. EmailIdentityService
```ruby
# web/app/services/email_identity_service.rb
class EmailIdentityService
  def initialize(pepper: nil)
    @pepper = pepper || ENV.fetch("SUBMISSION_EMAIL_HMAC_PEPPER", "demo-only-pepper-not-secret")
  end

  def hmac_email(email)
    OpenSSL::HMAC.hexdigest("SHA256", @pepper, email.to_s.strip.downcase)
  end

  def find_or_create_user(email)
    hmac = hmac_email(email)
    User.find_or_create_by!(email_hmac: hmac) do |u|
      u.role = "candidate"
    end
  end
end
```

### 3. Sluggable Concern
```ruby
# web/app/models/concerns/sluggable.rb
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_create :generate_masked_slug
  end

  private

  def generate_masked_slug
    return if public_slug.present?
    loop do
      self.public_slug = SecureRandom.hex(4).upcase
      break unless self.class.exists?(public_slug: public_slug)
    end
  end
end
```

### 4. AccessControlHelper
```ruby
# web/app/helpers/access_control_helper.rb
module AccessControlHelper
  def can_view_details?(resource)
    return false unless current_user
    return true if current_user.admin?
    return true if current_user.paid?
    return true if current_user.owner_of_review?(resource)
    false
  end
end
```

### 5. Model Scopes for Aggregates
Add scopes to Experience model for the common aggregate subquery:
```ruby
# In Experience model
scope :approved_aggregates_by_recruiter, -> {
  where(status: "approved")
    .joins(:interaction)
    .group("interactions.recruiter_id")
    .select("interactions.recruiter_id, COUNT(*) AS reviews_count, AVG(rating) AS avg_overall")
}
```

## Risks / Trade-offs
- **Behavioral parity**: Each extraction must be a pure refactoring — no behavior changes. Existing tests must pass without modification.
- **Admin auth**: Changing inheritance hierarchy could affect `before_action` ordering. Verify all admin routes still require auth.
- **Sluggable**: Removing the confusing guard clause in Recruiter changes behavior slightly (slugs with hyphens will no longer be regenerated). Verify this is the desired outcome.

## Migration Plan
- No data migration. Code-only refactoring.
- Run `rails test` after each extraction to verify no regressions.
