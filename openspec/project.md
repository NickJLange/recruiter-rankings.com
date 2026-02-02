# Project Context

## Purpose

Recruiter-Rankings.com is a privacy-focused platform for de-identified recruiter quality signals and candidate reviews. The platform serves as a proof-of-concept targeting ~$5/month hosting costs while maintaining strong data privacy protections, content moderation, and k-anonymity for aggregate data.

## Tech Stack

### Ruby on Rails Application (`web/`)
- **Ruby**: 3.4.7
- **Rails**: 8.1+
- **Database**: PostgreSQL (managed via Render.com)
- **Server**: Puma web server
- **Asset Pipeline**: Propshaft (modern Rails asset management)
- **Key Gems**: 
  - `pg` (PostgreSQL adapter)
  - `rack-attack` (rate limiting)
  - `pay` + `paddle` (payment processing)
  - `jekyll` (static site integration)
  - `faker` (seed data generation)
  - `capybara` + `selenium-webdriver` (system testing)
  - `brakeman` (security scanning)

### Static Site (`site/`)
- **Jekyll**: Static site generator for marketing pages
- Builds into Rails `public/` directory for unified hosting

### Infrastructure & Deployment
- **Platform**: Render.com (single free-tier service)
- **CI/CD**: Automatic deployment on push to main branch via `render.yaml`
- **Database**: Managed PostgreSQL with connection string injection
- **Regional**: Oregon (us-west-2)

## Project Conventions

### Code Style

- **Ruby Style**: Follow standard Rails conventions with Rubocop-style formatting
- **Naming**: Snake_case for variables and methods, PascalCase for classes
- **Controllers**: RESTful resource-oriented actions
- **Views**: ERB templates following Rails conventions
- **Migrations**: Descriptive action verbs (e.g., `add_index_to_users_on_email`)
- **No Comments**: Avoid adding comments unless explicitly requested

### Architecture Patterns

#### Hybrid Deployment Pattern
- **Monolithic Hosting**: Rails app and Jekyll site share single service
- **Build Pipeline**: Jekyll builds to `web/public/` before Rails compilation
- **Static Asset Serving**: Rails serves both dynamic and static content

#### Privacy-First Design
- **Data Anonymization**: Recruiters displayed with generated pseudonyms (RR-XXXXXXXXX format)
- **Envelope Encryption**: Two-tier encryption system with KEK (key-encryption-key)
- **k-Anonymity**: Aggregate data hidden until minimum thresholds met
- **Company Bucketing**: Small companies (<50 employees) grouped as "Small company"
- **HMAC Hashing**: Public email verification uses cryptographic pepper

#### Verification System
- **Challenge Token Pattern**: Users add tokens to LinkedIn profiles for verification
- **No LinkedIn API**: Simple HTTP fetch with custom user agent
- **Email Verification**: Envelope-encrypted storage with public HMAC hashes

#### Role-Based Access Control
- **Roles**: candidate, recruiter, moderator, admin
- **Protected Namespaces**: Admin interface at `/admin/` with basic auth
- **Moderation Pipeline**: pending → approved → public (or removed/flagged)

### Testing Strategy

- **Framework**: Minitest (Rails built-in)
- **Test Types**: Primarily integration tests covering user flows
- **Key Coverage Areas**:
  - Site endpoint functionality
  - Admin moderation workflows
  - Recruiter profile and JSON APIs
  - Locale persistence
  - Response creation workflows
- **Execution**: `rails test` runs full suite with parallel execution enabled
- **System Tests**: Capybara + Selenium for end-to-end browser testing

### Git Workflow

- **Branching**: Feature branches off main, merged via pull requests
- **Deployment**: Automatic on push to main branch via Render.com
- **Commit Messages**: Concise, focus on "why" not "what"
- **Pre-commit Hooks**: Run Brakeman security scanning in development

## Domain Context

### Core Entities & Relationships

#### Entities
- **Users**: Candidates, recruiters, moderators, and admins with role-based permissions
- **Recruiters**: Public profiles with company affiliations, verified via LinkedIn/email
- **Interactions**: Verified professional interactions between Users and Recruiters (replaces deprecated Review ownership)
- **Experiences**: Qualitative feedback (rating, body, dimensions) linked to an Interaction
- **Companies**: Recruiting target companies with size-based bucketing for privacy
- **Identity Challenges**: Token-based verification system for LinkedIn/email validation
- **Responses**: Recruiter right-of-reply to experiences

#### Workflows
1. **Review Submission**: User creates interaction → submits experience → moderation → approval → public display
2. **Recruiter Search**: Lookup by email/LinkedIn → return public aggregates with k-anonymity thresholds
3. **Moderation Queue**: Review pending content → approve/remove/flag → manage responses
4. **VerificationFlow**: Generate challenge token → add to LinkedIn profile → fetch and validate → mark verified

#### Rate Limiting Tiers
- **Unauthenticated**: Company aggregates and role listings only
- **Authenticated Human**: 2 reviews/month, email search (5/day), LinkedIn search (5/day)
- **Authenticated Bot**: 1 aggregate query per 6 months
- **Paid Authenticated Human**: Enhanced query limits and data access

### Privacy Constraints
- Companies with <50 employees always displayed as "Small company"
- Review aggregators hidden below minimum review count (default: 5)
- Public email addresses stored as HMAC hashes only
- Email addresses encrypted at rest with envelope encryption
- Right-of-reply system for verified recruiters to respond to reviews

## Important Constraints

### Budget & Hosting
- **Target**: $5/month on Render.com free tier
- **Architecture**: Single service shared between Rails app and Jekyll site
- **Database**: Free tier PostgreSQL with connection limits
- **Storage**: Minimal external storage to avoid egress fees

### Performance
- **LinkedIn Fetch**: 5-second timeout for verification requests
- **Pagination**: 10 items per page, max 50 per page
- **Concurrency**: 2 workers × 5 threads per worker on Render

### Security & Moderation
- **Rate Limits**: ≤10 reviews per 24 hours per IP
- **Minimum Account Age**: Required prevent abuse
- **Approval Required**: All reviews need moderator approval (except demo mode)
- **Admin Access**: Basic HTTP auth on `/admin/*` namespace

### Regulatory & Privacy
- **k-Anonymity**: No aggregate data displayed below minimum thresholds
- **Data Minimization**: Only collect necessary information
- **Right-to-be-Forgotten**: Ability to remove reviews and pseudonyms
- **Company Privacy**: Small companies protected from identification

## External Dependencies

### Third-Party Services
- **LinkedIn**: Public profile scraping for verification (no API usage)
- **Render.com**: Hosting platform with managed PostgreSQL
- **Paddle**: Payment processing via Pay gem

### External Systems
- **Email Delivery**: Rails ActionMailer (SMTP configuration TBD)
- **GitHub**: Repository hosting and deployment triggers

### Infrastructure Dependencies
- **PostgreSQL**: Primary database with managed hosting
- **Redis**: Not currently used; potential future caching layer
- **CDN**: Not currently used; direct asset serving from Rails

### Network Considerations
- **LinkedIn Access**: Requires custom user agent string and timeout handling
- **Database Access**: Only allowed from Render services (ipAllowList: [])
- **Static Assets**: Served directly from Rails public directory