# Recruiter-Rankings — Gameplan and Technical Design (POC)

Canonical domain: recruiter-rankings.com (with hyphen)
Launch region: US (single-region POC)
Budget target: ~$5/month

Mission
Improve the recruiter–candidate experience by publishing de-identified, standardized quality signals for recruiters and enabling a safe right-of-reply. Public value first (directory + metrics), with a path to B2B benchmarks.

POC Success Metrics
- 100 verified reviews
- 500 candidate signups
- 50 recruiter profiles claimed

Primary Users
- Public/Candidates: browse de-identified recruiter metrics; submit reviews
- Recruiters: claim profile; right-of-reply
- Internal (founders/moderators): moderation and takedowns

Policies and Guardrails (POC)
- Right-of-reply: yes for verified recruiters; aim to review within 7 days prior to publishing new reviews to minimize slander risk when possible
- Takedown policy: default to takedown to reduce risk; SLA 7 days standard, 3 days urgent
- Compliance scope: GDPR (note: US launch — include basic CCPA/CPRA handling for deletion/access)
- Data type for POC: synthetic-only

Value Proposition and Content Model
- Public directory: yes; aggregated, de-identified metrics (no PII in public)
- Company visibility: bucket companies < 50 employees as “Small company”
- Company-to-company comparisons: allowed on aggregated metrics only; strict suppression thresholds
- Standard question dimensions (1–5 stars; show overall + sub-scores):
  - Responsiveness
  - Clarity/accuracy of role description
  - Understanding candidate needs / special circumstances
  - Fairness and inclusivity
  - Timeline management
  - Feedback quality
  - Professionalism/respect
  - Job–role match quality
  - Outcome (screen/reject/offer)
- Hiring stage distribution: not in POC

Monetization
- Near-term: SEO/traffic (ads later if desired)
- Later (B2B reports):
  - Signals: time-to-first-response, response rate, candidate satisfaction, benchmarks vs peers
  - Identity reveal: never by default; opt-in only per party (consent-based)
  - Pricing hypothesis (placeholder): $500–$1,500 per pilot report; TBD based on data volume
- Additional future revenue (allowed): profile-claim subscription; benchmarking subscriptions; API/data feed; job board/affiliate; sponsored placements

Identity and Verification
- No LinkedIn partner API. Use non-API profile challenge:
  - User adds a one-time challenge token to LinkedIn profile (Website/Featured/About). Token space is large (128-bit) to prevent collisions/guessing
  - Token TTL: 7 days; re-verify at profile-claim and annually
- Recruiter verification: via LinkedIn profile challenge for POC; add work-email proof later
- Fraud prevention: ≤10 reviews/account/24h; minimum account age 24h; IP/UA rate limits; high-similarity text detection

Data Security and Privacy (POC)
- Email handling: publicly reference only HMAC(email, server-side pepper). Store raw email encrypted at rest with envelope encryption
  - Envelope encryption: generate DEK to encrypt email; store DEK encrypted by a KEK (key-for-the-key). Rotate KEK without re-encrypting all data
- PII retention (POC): 180 days (unless deletion is requested sooner)
- Additional metadata: IP, user agent, timestamps retained 30 days for abuse prevention; never shown publicly
- Logging/observability: redact emails/IPs from logs; store only hashes/opaque IDs; structured logs
- DSR/takedown workflow: email-based requests; verify requester identity; log actions and outcomes
- Cross-border: single-region US for POC; plan for regional isolation later (region tags + export controls)

Threat Model (prioritized)
1) Account takeover
2) Scraping/enumeration of identities
3) Libel/slander injection
4) Spam/fake accounts
5) Insider access misuse
6) Data exfiltration

Technical Design (POC)
- Stack: Ruby on Rails app for dynamic functionality; Jekyll (optional) for static marketing pages
- Database: Postgres
- Hosting: target Railway or Render free/low-cost; DB on Neon or Railway/Render managed Postgres
- Non-functional: p95 < 500 ms; cold starts acceptable; metrics + tracing enabled

High-Level Architecture
- Web: Rails (API + server-rendered pages). Public directory read-heavy; admin/moderation behind auth
- Static site (optional): Jekyll for marketing pages; can be deployed to GitHub Pages/Cloudflare Pages if desired
- Database: Postgres with logical partitioning (region, company); suppression thresholds for public aggregates
- Background jobs: async verification (LinkedIn token fetch/check), moderation pipeline, email

Data Model (initial)
- users(id, role, email_hmac, email_ciphertext, email_kek_id, linked_in_url, created_at, …)
- recruiters(id, name, company_id, region, email_hmac, email_ciphertext, email_kek_id, public_slug, verified_at, …)
- companies(id, name, size_bucket, website_url, region, …)
- reviews(id, user_id, recruiter_id, company_id, overall_score, text, created_at, status[pending|approved|removed|flagged], …)
- review_metrics(id, review_id, dimension, score)
- identity_challenges(id, subject_type[user|recruiter], subject_id, token, token_hash, expires_at, verified_at)
- takedown_requests(id, subject_type, subject_id, reason_code, requested_by, status, sla_due_at, resolved_at)
- moderation_actions(id, actor_id, action, subject_type, subject_id, notes, created_at)
- profile_claims(id, recruiter_id, user_id, method[LI|email], verified_at, revoked_at)

Indexes and Constraints
- Unique(email_hmac) where applicable; do not expose raw emails
- Partial indexes for region/company filters
- Suppress public aggregates until k-anonymity threshold (e.g., n ≥ 5 reviews)

Identity/Verification Flow
- User submits LinkedIn URL; app generates token; user places token on profile; app verifies by fetching profile (rate-limited); on success, set verified_at
- Challenge tokens are 128-bit random; TTL 7 days; hashed tokens stored (no plaintext)

Moderation Pipeline (cheap-first)
- Step 1: Regex PII scrubbers (emails, phones, URLs); auto-redact and flag
- Step 2: Cheap hosted LLM for toxicity/defamation heuristics (OpenAI/Anthropic low-cost tier)
- Step 3: Human moderator review for flagged/borderline

Access Controls
- Anonymous: view aggregated metrics only
- Candidate: submit reviews; view aggregates
- Recruiter: claim profile; respond to reviews; view aggregates
- Moderator: review flags; manage takedowns
- Admin: full access; audit logs required for all privileged actions

Observability
- Metrics: request rate, latency, error rates, moderation queue depth
- Tracing: enable per-request tracing (sampling); do not include PII in spans
- Alerts: SLA breaches for takedowns; verification backlog

Sharding and Scalability
- Long-term sharding keys: geography, company
- POC: logical partitioning with region/company tags; partial indexes; background jobs for heavy reads to precompute aggregates

Secrets Management
- POC: platform environment variables (no plaintext in repo). KEK provided via env; rotate KEK periodically; store current KEK id

Roadmap
- POC (4–6 weeks): core models, review submission, verification (LI token), moderation, public directory, basic admin, metrics/tracing
- Beta: recruiter claim workflow, right-of-reply UI, suppression thresholds, basic B2B report skeleton
- GA: expanded compliance (full GDPR/CCPA self-serve DSR), regional isolation, pricing/payments, hardened anti-abuse

Hosting Options (Rails + Postgres on free/near-free)
- Option A: Render Free Web Service + Neon Postgres Free
  - Pros: simple; Postgres branching; good developer UX
  - Cons: free tier sleeps; cold starts
- Option B: Railway Free Dev + Railway Postgres
  - Pros: one platform; easy deployments
  - Cons: usage limits; services may sleep
- Option C: Fly.io (free allowances) for Rails + Neon/Supabase Postgres
  - Pros: good performance; regional control
  - Cons: more setup complexity
- Notes: keep PII synthetic for POC; if real data is later introduced, upgrade to paid tiers with better audit/KMS
