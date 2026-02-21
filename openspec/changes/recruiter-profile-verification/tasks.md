# Tasks: Recruiter Profile Verification

## Status
Draft — 2026-02-21

## Dependency
`integrate-clerk-auth` must be merged first (or this branch must be based on it). The Clerk claim flow sets `verified_at`; this change reads `verified_at` in the admin view for informational display only.

---

## Task 1: Migration — add `visibility_override` to recruiters

**File:** `web/db/migrate/<timestamp>_add_visibility_override_to_recruiters.rb`

```ruby
class AddVisibilityOverrideToRecruiters < ActiveRecord::Migration[8.1]
  def change
    add_column :recruiters, :visibility_override, :boolean, null: false, default: false
  end
end
```

- Safe for zero-downtime deploy (Postgres default fills existing rows before commit)
- After running, `web/db/schema.rb` must reflect the new column

**Acceptance:** `rails db:migrate` succeeds; schema shows `visibility_override: false` default.

---

## Task 2: Recruiter model — add `visibility_overridden` scope

**File:** `web/app/models/recruiter.rb`

Add a named scope for use in the admin controller:

```ruby
scope :visibility_overridden, -> { where(visibility_override: true) }
```

This is a clarity aid for queries; the controller may also inline the condition. Either is acceptable.

**Acceptance:** `Recruiter.visibility_overridden` returns only recruiters with `visibility_override = true`.

---

## Task 3: RecruitersController — update index threshold filter

**File:** `web/app/controllers/recruiters_controller.rb` (line 11)

Change:
```ruby
.where("agg.reviews_count >= ?", threshold)
```

To:
```ruby
.where("agg.reviews_count >= ? OR recruiters.visibility_override = true", threshold)
```

The rest of the index action (filters, pagination, JSON response) is unchanged.

**Acceptance:**
- A recruiter with 0 reviews and `visibility_override = true` appears in `GET /person`
- A recruiter with 0 reviews and `visibility_override = false` does NOT appear in `GET /person`
- A recruiter with ≥ k reviews appears regardless of `visibility_override`

---

## Task 4: Admin::RecruitersController — new controller

**File:** `web/app/controllers/admin/recruiters_controller.rb`

```ruby
module Admin
  class RecruitersController < BaseController
    def index
      threshold = public_min_reviews
      aggregates = Experience.approved_aggregates_by_recruiter

      @recruiters = Recruiter
        .joins("LEFT JOIN (#{aggregates.to_sql}) agg ON agg.recruiter_id = recruiters.id")
        .left_joins(:company)
        .preload(:company)
        .where("COALESCE(agg.reviews_count, 0) < ? OR recruiters.visibility_override = true", threshold)
        .select("recruiters.*, COALESCE(agg.reviews_count, 0) AS reviews_count")
        .order("recruiters.visibility_override DESC, reviews_count DESC, recruiters.name ASC")
    end

    def toggle_visibility
      @recruiter = Recruiter.find(params[:id])
      new_val = !@recruiter.visibility_override
      reviews_count = @recruiter.attributes["reviews_count"] ||
        Experience.approved_aggregates_by_recruiter
          .where(recruiter_id: @recruiter.id)
          .pluck(:reviews_count).first.to_i
      @recruiter.update!(visibility_override: new_val)
      ModerationAction.create!(
        actor: current_moderator_actor,
        action: "set_visibility_override:#{new_val}",
        subject: @recruiter,
        notes: "reviews_count at time of toggle: #{reviews_count}"
      )
      redirect_to admin_recruiters_path,
        notice: "#{@recruiter.name}: visibility override set to #{new_val}."
    end

    protect_from_forgery with: :exception
  end
end
```

**Notes:**
- Inherits `require_moderator_auth` and `current_moderator_actor` from `Admin::BaseController`
- `public_min_reviews` is available via `ApplicationController` (inherited through `BaseController`)
- `protect_from_forgery` matches the pattern in `Admin::ReviewsController`

**Acceptance:**
- `GET /admin/recruiters` requires Basic Auth, returns 200 with list of sub-threshold recruiters
- `PATCH /admin/recruiters/:id/toggle_visibility` flips `visibility_override` and redirects
- `ModerationAction` is created on each toggle

---

## Task 5: Routes — add admin recruiter routes

**File:** `web/config/routes.rb`

Inside the `namespace :admin` block (after the existing `identity_verifications` resource):

```ruby
resources :recruiters, only: [:index] do
  member do
    patch :toggle_visibility
  end
end
```

**Acceptance:** `rails routes | grep admin_recruiter` shows:
```
admin_recruiters        GET    /admin/recruiters(.:format)
toggle_visibility_admin_recruiter PATCH /admin/recruiters/:id/toggle_visibility(.:format)
```

---

## Task 6: Admin view — sub-threshold recruiter list

**File:** `web/app/views/admin/recruiters/index.html.erb`

Minimal ERB table:

```erb
<h1>Recruiter Visibility Overrides</h1>
<p>Showing recruiters below the k=<%= public_min_reviews %> threshold plus any with overrides active.</p>

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Company</th>
      <th>Reviews</th>
      <th>Verified</th>
      <th>Override</th>
      <th>Action</th>
    </tr>
  </thead>
  <tbody>
    <% @recruiters.each do |recruiter| %>
      <tr>
        <td><%= link_to recruiter.name, person_path(recruiter.public_slug) %></td>
        <td><%= recruiter.company&.name %></td>
        <td><%= recruiter.attributes["reviews_count"].to_i %></td>
        <td><%= recruiter.verified_at ? "Yes (#{recruiter.verified_at.to_date})" : "No" %></td>
        <td><%= recruiter.visibility_override ? "ON" : "off" %></td>
        <td>
          <%= button_to recruiter.visibility_override ? "Remove Override" : "Grant Override",
              toggle_visibility_admin_recruiter_path(recruiter),
              method: :patch %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

**Notes:**
- `button_to` generates a CSRF-protected form automatically
- `person_path` uses the recruiter's `public_slug` (the `:slug` param from routes)

**Acceptance:** Page renders without error; toggle buttons submit correct PATCH requests.

---

## Task 7: ModerationAction audit — verify no schema change needed

**File:** `web/app/models/moderation_action.rb` (read-only verification)

`ModerationAction` uses `belongs_to :subject, polymorphic: true`. This already supports any model as subject. Verify `moderation_actions` table has `subject_type` and `subject_id` columns (confirmed in schema).

No code change required. Document that `Recruiter` is now a valid `subject_type` value for `ModerationAction`.

**Acceptance:** Creating a `ModerationAction` with `subject: recruiter_instance` succeeds in console/tests.

---

## Task 8: Tests

**File:** `web/test/controllers/admin/recruiters_controller_test.rb`

### Test cases

**`GET /admin/recruiters`**
- Without auth → 401
- With auth, recruiter below threshold, no override → appears in list
- With auth, recruiter at/above threshold → does NOT appear in list (unless override)
- With auth, recruiter below threshold with override → appears in list

**`PATCH /admin/recruiters/:id/toggle_visibility`**
- Without auth → 401
- With auth, override=false → sets to true, creates ModerationAction, redirects
- With auth, override=true → sets to false, creates ModerationAction, redirects

**`GET /person` (RecruitersController#index integration)**
- Recruiter below threshold, no override → hidden from listing
- Recruiter below threshold, override=true → visible in listing
- Recruiter at threshold, override=false → visible in listing (existing behavior preserved)

### Fixture setup
Use existing fixtures from `web/test/fixtures/`:
- `users.yml` — `moderator` fixture already exists for auth
- Add a `below_threshold_recruiter` entry to `recruiters.yml` (or create inline in test)

### Pattern reference
Follow `web/test/controllers/admin/reviews_controller_test.rb` for Basic Auth setup and action testing.

**Acceptance:** All new tests pass; no existing tests broken; `PARALLEL_WORKERS=1 rails test` exits 0.

---

## Completion Checklist

- [ ] Task 1: Migration created and run
- [ ] Task 2: Model scope added
- [ ] Task 3: RecruitersController#index filter updated
- [ ] Task 4: Admin::RecruitersController created
- [ ] Task 5: Routes added
- [ ] Task 6: Admin view created
- [ ] Task 7: ModerationAction audit confirmed (no change)
- [ ] Task 8: Tests written and passing
- [ ] All three openspec files internally consistent
- [ ] Dependency on `integrate-clerk-auth` noted in branch or PR description
