# Data Model Migration: Review → Interaction/Experience

## Current State

The codebase has two parallel data models for recruiter feedback:

### Legacy Model: Review
- **Table**: `reviews` (columns: user_id, recruiter_id, company_id, overall_score, text, status)
- **Used by**: Admin moderation pipeline (`Admin::ReviewsController`), `ReviewsController#create`
- **Associations**: `has_many :review_metrics`, `has_many :review_responses`
- **Status**: Active but deprecated — still receives writes from `ReviewsController#create`

### Current Model: Interaction + Experience
- **Tables**: `interactions` (recruiter_id, target_id, role_id, status, occurred_at) + `experiences` (interaction_id, rating, body, status, would_recommend)
- **Used by**: Public read paths (`RecruitersController#show`, `CompaniesController#show`), aggregate scopes
- **Associations**: Experience `has_many :review_metrics` (dimensional scores)
- **Status**: Primary model for public data display

### ReviewMetric (Shared)
- **Table**: `review_metrics` (experience_id, dimension, score)
- **Note**: Despite the "review_" prefix, this model belongs_to `:experience`. The naming is a historical artifact.
- **Bug**: `ReviewsController#create` tries to call `review.review_metrics.create!` but ReviewMetric has no `review_id` column (it has `experience_id`). This causes `ActiveModel::UnknownAttributeError` on every review submission with `copy_overall_to_dimensions?` enabled.

## Code Path Map

| Path | Controller | Model Used | Notes |
|------|-----------|------------|-------|
| Public write | `ReviewsController#create` | Review (legacy) | Creates Review record; ReviewMetric creation broken |
| Public read (JSON) | `ReviewsController#index` | Review (legacy) | Returns Review records for a recruiter |
| Public read (profile) | `RecruitersController#show` | Experience (current) | Aggregates from Experience + Interaction |
| Public read (company) | `CompaniesController#show` | Experience (current) | Aggregates from Experience + Interaction |
| Admin read | `Admin::ReviewsController#index` | Review (legacy) | Moderation queue |
| Admin actions | `Admin::ReviewsController#approve/flag/remove` | Review (legacy) | Status transitions |
| Admin responses | `Admin::ResponsesController` | ReviewResponse (legacy) | Belongs to Review |

## Future Migration Plan

### Phase 1: Fix the ReviewMetric Bug
- Update `ReviewsController#create` to also create an Interaction + Experience alongside the Review
- Or: change ReviewMetric to be created via the Experience path

### Phase 2: Unify Admin to Read from Experience
- Modify `Admin::ReviewsController` to query Experience instead of Review
- Create equivalent admin actions (approve/flag/remove) for Experience status transitions
- Migrate ReviewResponse to associate with Experience instead of Review

### Phase 3: Migrate Historical Data
- Write a migration script to create Interaction + Experience records for each existing Review
- Preserve all ReviewMetric associations (already correctly linked to Experience)
- Verify data integrity before proceeding

### Phase 4: Drop Review
- Remove `ReviewsController` index action (or redirect to Experience-based endpoint)
- Remove Review, ReviewResponse models
- Drop `reviews`, `review_responses` tables
- Rename `ReviewMetric` to `ExperienceMetric` (optional, low priority)

## Prerequisites
- Test coverage for admin workflows (completed in `test-coverage-gaps` change)
- Admin::BaseController extraction (completed in `dry-extraction` change)
- Security hardening (completed in `security-hardening` change)
