# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview

Recruiter-Rankings.com is a platform for de-identified recruiter quality signals and candidate reviews. The project consists of a Ruby on Rails web application with a Jekyll-based static marketing site, designed as a POC targeting ~$5/month hosting budget with a focus on data privacy and moderation.

## Architecture

### Hybrid Structure
- **Rails App** (`web/`): Core dynamic functionality including review submission, recruiter profiles, and admin moderation
- **Jekyll Site** (`site/`): Static marketing pages that build into Rails' public directory for unified hosting
- **Deployment**: Single Render.com service with managed PostgreSQL, configured via `render.yaml`

### Key Privacy & Security Features
- Email addresses stored as HMAC hashes publicly, encrypted at rest with envelope encryption
- LinkedIn verification via challenge tokens (no API required)
- Rate limiting with rack-attack
- Moderation pipeline with auto-approval flags for demo/development

### Data Model Core Entities
- **Users**: Candidates, recruiters, moderators, admins with role-based access
- **Recruiters**: Public profiles with company affiliations, verified via LinkedIn or email
- **Reviews**: Star ratings (1-5) across multiple dimensions with moderation workflow
- **Companies**: Size-bucketed to protect small companies (<50 employees = "Small company")
- **Identity Challenges**: Token-based verification system for LinkedIn/email validation

## Development Commands

### Local Development Setup
```bash
cd web/
bundle install
rails db:setup
rails db:migrate
rails db:seed  # Creates demo data
bin/dev  # Starts Rails server
```

### Jekyll Static Site (Marketing Pages)
```bash
cd site/
bundle install
bundle exec jekyll serve --livereload  # Development preview
bundle exec jekyll build  # Builds to ../web/public/
```

### Database Operations
```bash
cd web/
rails db:create
rails db:migrate
rails db:rollback  # Rollback last migration
rails db:reset     # Drop, create, migrate, seed
rails console      # Access Rails console
```

### Testing
```bash
cd web/
rails test                    # Run all tests
rails test:integration        # Integration tests only
rails test test/integration/site_endpoints_test.rb  # Single test file
```

### Production Deployment
Deployment is automatic via Render.com when pushing to the main branch. The `render.yaml` configures:
- Rails app with Puma server
- Managed PostgreSQL database
- Jekyll build process for static assets
- Environment variables for production configuration

## Important Configuration

### Environment Variables
Key variables defined in `web/.env.example`:
- `PUBLIC_MIN_REVIEWS`: Minimum reviews threshold for public display (default: 5)
- `SUBMISSION_EMAIL_HMAC_PEPPER`: Cryptographic pepper for email hashing
- `LINKEDIN_FETCH_TIMEOUT`: Timeout for LinkedIn verification requests
- `DEMO_AUTO_APPROVE`: Auto-approve reviews in demo mode
- `CANONICAL_URL`: Base URL for sitemap and meta tags

### Moderation & Privacy
- Reviews require approval before public display (unless `DEMO_AUTO_APPROVE=true`)
- Companies with <50 employees are bucketed as "Small company" for privacy
- k-anonymity thresholds prevent displaying aggregates with insufficient data
- Right-of-reply system for verified recruiters

### Rate Limiting
Configured in `web/config/initializers/rack_attack.rb`:
- ≤10 reviews per account per 24 hours
- IP-based rate limiting for abuse prevention
- Minimum account age requirements

## Development Notes

### Ruby Version
- Uses Ruby 3.4.5 (specified in `web/.ruby-version`)
- Rails 8.0.2+ with modern asset pipeline (Propshaft)

### Database Constraints
The migration includes comprehensive check constraints for data integrity:
- Review scores: 1-5 range validation
- User roles: candidate|recruiter|moderator|admin
- Review status: pending|approved|removed|flagged
- Verification methods: li|email for identity challenges

### Admin Interface
Admin functions accessible at `/admin/` with basic auth (development defaults: mod/mod). Includes:
- Review moderation queue
- Response management for recruiter replies
- Dashboard with key metrics

### Unique Features
- **Pseudonym Generation**: Recruiters displayed with generated pseudonyms (RR-XXXXXXXXX) for privacy
- **LinkedIn Verification**: Challenge token system where users add tokens to LinkedIn profiles for verification
- **Envelope Encryption**: Email addresses encrypted with key-encryption-key (KEK) system for security
- **Suppression Thresholds**: Public aggregates hidden until sufficient review volume for k-anonymity

## Testing Strategy

Tests are primarily integration tests focusing on user flows:
- Site endpoint functionality
- Admin moderation workflows  
- Recruiter profile and review JSON APIs
- Locale persistence
- Response creation and management

Use `rails test` to run the full test suite. Tests use Rails' built-in Minitest framework with parallel execution enabled.
