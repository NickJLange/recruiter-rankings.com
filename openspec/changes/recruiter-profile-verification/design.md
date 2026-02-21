# Design: Recruiter Profile Verification

## Status
Draft — 2026-02-21

---

## Decision 1: Visibility Model

### Rule
A recruiter profile is publicly visible in `RecruitersController#index` when:

```
agg.reviews_count >= PUBLIC_MIN_REVIEWS
  OR recruiters.visibility_override = true
```

This is a minimal change to the existing query in `web/app/controllers/recruiters_controller.rb:11`:

```ruby
# Current
.where("agg.reviews_count >= ?", threshold)

# After
.where("agg.reviews_count >= ? OR recruiters.visibility_override = true", threshold)
```

The `show` action (`RecruitersController#show`) does not filter by threshold — it loads by slug directly. No change needed there; a profile can always be accessed by direct URL if you know the slug, consistent with the current behavior.

### Relationship to `verified_at`
`recruiters.verified_at` (already in schema) records when the recruiter completed an identity challenge. It is a separate concept from visibility. A future change may use `verified_at` to surface a "verified" badge on the profile page, but it does not affect the listing threshold. These two fields must not be conflated.

| Field | Meaning | Set By |
|-------|---------|--------|
| `verified_at` | Recruiter has completed identity challenge | `ClaimIdentityController#verify` |
| `visibility_override` | Admin has force-enabled public listing below k | `Admin::RecruitersController#toggle_visibility` |

---

## Decision 2: Database Change

Add one column to `recruiters`:

```ruby
# Migration
add_column :recruiters, :visibility_override, :boolean, null: false, default: false
```

- `null: false, default: false` — safe for zero-downtime deploy (Postgres fills existing rows with false before the migration commits)
- No index needed — the override is rare; full-table scans on this column in the admin view are acceptable

Reference: `web/db/schema.rb:190` — existing `recruiters` columns.

---

## Decision 3: Admin Override Controller

### Inheritance
`Admin::RecruitersController < Admin::BaseController`

This picks up:
- `before_action :require_moderator_auth` (HTTP Basic Auth)
- `current_moderator_actor` helper (returns the moderator `User`)

Reference: `web/app/controllers/admin/base_controller.rb`

### Actions

**`index`** — List sub-threshold recruiters (those not yet meeting the k-review bar), sorted by `reviews_count DESC`. Includes `visibility_override` current state for each. Also shows overridden-but-verified recruiters so admins can see the full picture.

Query:
```ruby
aggregates = Experience.approved_aggregates_by_recruiter
Recruiter
  .joins("LEFT JOIN (#{aggregates.to_sql}) agg ON agg.recruiter_id = recruiters.id")
  .where("COALESCE(agg.reviews_count, 0) < ? OR recruiters.visibility_override = true", threshold)
  .select("recruiters.*, COALESCE(agg.reviews_count, 0) AS reviews_count")
  .order("visibility_override DESC, reviews_count DESC")
```

**`toggle_visibility`** — Flips `visibility_override` for a single recruiter and logs a `ModerationAction`.

```ruby
def toggle_visibility
  @recruiter = Recruiter.find(params[:id])
  new_val = !@recruiter.visibility_override
  @recruiter.update!(visibility_override: new_val)
  ModerationAction.create!(
    actor: current_moderator_actor,
    action: "set_visibility_override:#{new_val}",
    subject: @recruiter,
    notes: "reviews_count at time of toggle: #{@recruiter.reviews_count}"
  )
  redirect_to admin_recruiters_path, notice: "Visibility override set to #{new_val} for #{@recruiter.name}."
end
```

Pattern reference: `web/app/controllers/admin/reviews_controller.rb` — `transition!` method.

---

## Decision 4: Routes

Add inside the existing `namespace :admin` block in `web/config/routes.rb:25`:

```ruby
resources :recruiters, only: [:index] do
  member do
    patch :toggle_visibility
  end
end
```

This generates:
- `GET  /admin/recruiters` → `admin_recruiters_path`
- `PATCH /admin/recruiters/:id/toggle_visibility` → `toggle_visibility_admin_recruiter_path(id:)`

Note: `resources :identity_verifications` is already in the admin namespace (routes.rb:41). The new `recruiters` resource is parallel to it.

---

## Decision 5: Audit Logging

Every `toggle_visibility` call creates a `ModerationAction` record:

```
action: "set_visibility_override:true"   # or :false
subject: <Recruiter>                      # polymorphic
actor: current_moderator_actor            # User with role=moderator
notes: "reviews_count at time of toggle: N"
```

`ModerationAction` is already polymorphic (`belongs_to :subject, polymorphic: true`), so no schema change is needed to support `Recruiter` as a subject type.

Reference: `web/app/models/moderation_action.rb`

---

## Decision 6: Admin View

A simple ERB table at `web/app/views/admin/recruiters/index.html.erb`:

Columns:
- Name (linked to public profile)
- Company
- Reviews count
- Override status (Yes/No)
- Toggle button (PATCH form, CSRF-safe)

The toggle button submits a PATCH form inline. No JavaScript required. Consistent with the existing admin review UI pattern.

---

## Decision 7: Scope Exclusions (Explicit)

The following are explicitly **not** in scope and must not be implemented as part of this change:

1. **Clerk LinkedIn OAuth claim flow** — belongs in `integrate-clerk-auth`
2. **Deprecating or removing the token-challenge claim flow** (`ClaimIdentityController`) — separate cleanup
3. **Verified badge on public profile pages** — depends on UX decisions not yet made
4. **Per-recruiter threshold** — not needed
5. **Email notification to recruiter on override** — not in scope; would require email infrastructure decisions

---

## Files Changed

| File | Change |
|------|--------|
| `web/db/migrate/<timestamp>_add_visibility_override_to_recruiters.rb` | New migration |
| `web/db/schema.rb` | Updated by migration |
| `web/app/models/recruiter.rb` | Add `scope :visibility_overridden` (optional, for clarity) |
| `web/app/controllers/recruiters_controller.rb` | Update index WHERE clause |
| `web/app/controllers/admin/recruiters_controller.rb` | New file |
| `web/app/views/admin/recruiters/index.html.erb` | New file |
| `web/config/routes.rb` | Add admin recruiter routes |
| `web/test/controllers/admin/recruiters_controller_test.rb` | New test file |
