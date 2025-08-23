# Recruiter-Rankings: Gameplan Draft Questionnaire

Instructions
- Provide short, concrete answers (bullets are fine).
- Assume emails are stored but never publicly displayed unless stated otherwise.
- POC can use synthetic data unless you explicitly choose real data.

Open contradictions and decisions to clarify
- Public PII lists recruiter email, but later states emails should never appear. Clarify: store email but never display publicly?
- LinkedIn challenge token may be difficult without partner API access. Are you OK with non-API verification alternatives?
- DB sharding: clarify the sharding dimension (geography, company, recruiter-id hash, or other).
- Capturing decoded identities for future use risks purpose creep. Confirm intent and consent model.
- Domain: recruiterrankings.com (no hyphen) vs recruiter-rankings.com (hyphen). Which is canonical?

1) Vision, scope, and audience
- Primary launch regions (e.g., US, EU, UK, other):
- Initial primary user (candidates or companies buying reports):
- Secondary users:
- Recruiter types in scope (in-house, agency, sourcers, coordinators):
- Individual vs agency-level ratings:
- Minimum validation for a review (e.g., confirmed interaction within last 12 months, evidence type):
- POC success metrics (e.g., 100 verified reviews, 500 candidate signups, 50 recruiter profiles claimed):

2) Value proposition and content model
- Public directory with aggregated, de-identified metrics? (yes/no):
- Right-of-reply for recruiters after verification? (yes/no):
- Standardized question dimensions (pick top 6–8 and add any):
  - Responsiveness
  - Clarity/accuracy of role description
  - Fairness and inclusivity
  - Timeline management
  - Feedback quality
  - Professionalism/respect
  - Job-role match quality
  - Outcome (screen/reject/offer)
- Rating format (1–5 stars, NPS, yes/no, weighted composite):
- Show distribution by hiring stages? (yes/no). If yes, confirm stages:
  - Sourced → Recruiter Screen → HM Screen → Onsite/Loop → Offer → Decision
- Company visibility: hide companies < 50 staff entirely, or show as Small company bucket?:
- Company-to-company comparisons (allowed/not allowed). If allowed, guardrails:
- Browser extension in POC? (yes/no). If yes, flows to include (e.g., capture from Gmail/LinkedIn, quick-rate):

3) Monetization and pricing
- Prioritize near-term revenue: SEO/ads vs B2B reports vs other:
- Private report buyers (talent leadership, HR, procurement, other):
- Signals included in paid reports (choose):
  - Time-to-first-response, response rate
  - Funnel conversion by stage
  - Candidate NPS by recruiter
  - SLA adherence
  - Benchmarks vs peers
- Identity reveal policy for any decoded identities (never by default, opt-in only, contractual only):
- Pricing hypothesis (starter range):
- Additional revenue ideas (select any allowed):
  - Recruiter claim-your-profile subscriptions
  - Company benchmarking subscriptions
  - API/data feed
  - Job board/affiliate
  - Sponsored profiles/placements
- Non-starters (explicitly exclude):

4) Policy, moderation, and legal
- Takedown policy grounds (falsifiable facts, doxxing, PII leakage, hate speech, court orders, other):
- Takedown SLA targets (e.g., 72h standard, 24h urgent):
- Right-of-reply process for recruiters (yes/no). If yes, constraints:
- Geographic compliance scope for POC (GDPR, UK GDPR, CCPA/CPRA, PIPEDA, other):
- Data subject requests (access, deletion, correction) handled in POC? (yes/no):
- POC data type (synthetic-only, real with consent, mixed):
- Moderation approach (cheap model + escalation). Budget per 1k items and target latency:

5) Identity and verification
- LinkedIn API access/partner status available? (yes/no):
- If no, acceptable user verification methods (choose):
  - LinkedIn profile challenge (temporary code in Website/Featured)
  - Email magic link
  - GitHub gist
  - X/Twitter post
  - DNS TXT for corporate domains
- Recruiter verification (choose):
  - Work email proof (@company.com)
  - Domain-based proof
  - LinkedIn company association proof
- Challenge token TTL and re-verification frequency:
- Fraud prevention thresholds (e.g., number of reviews per account/day, minimum account age):

6) Data security and privacy
- Emails: store HMAC(email, secret pepper) for public refs and encrypt raw email at rest? (yes/no):
- Additional metadata to store (IP, user agent, timestamps, geo) and retention:
- PII retention defaults for POC (e.g., 180 days, 1 year):
- Unstructured review text retention and redaction policy:
- Access roles and permissions (anonymous, candidate, recruiter, moderator, admin) and visibility per role:
- Cross-border strategy for POC (single region now, regional isolation later):
- Takedown/DSR workflow (email-only, web form, both) and identity proof required:
- Logging and observability redaction (avoid storing emails/IPs in logs; mask by default):
- Threats to prioritize (rank): account takeover, scraping/enum, libel injection, spam/fake accounts, insider access, data exfiltration:

7) Technical stack and constraints
- Preferred stack (TypeScript, Next.js/SvelteKit/Remix, Node/Deno):
- Database preference (Postgres via Neon/Supabase, MySQL via PlanetScale, SQLite via Turso/Cloudflare D1):
- Hosting region(s) for POC:
- Monthly budget target ($0–$5 typical):
- Performance targets (p95 latency, cold starts acceptable?):
- Observability (basic logs only, plus metrics, plus tracing):
- Feature flags and config management approach:
- Moderation model choice (open-source small model vs hosted cheap LLM) and provider shortlist:

8) Sharding and scalability
- Sharding dimension long-term (geography, company, recruiter-id hash, tenant):
- For POC, is logical partitioning enough (row-level region tags + partial indexes)? (yes/no):
- Expected 6-month scale (number of recruiter profiles, companies, reviews):

9) Hosting for POC (pick one or propose)
- Options shortlist:
  - Vercel (Hobby) + Neon (Postgres)
  - Netlify (Free) + Supabase (Postgres)
  - Cloudflare Pages + Workers + D1 (SQLite)
  - PlanetScale (MySQL) + Vercel/Netlify
  - Railway (Free dev) + Postgres
  - Fly.io (free allowances) containers + managed DB
  - Render (free web service) + managed DB
- Data residency constraints that affect choice:
- Secrets management approach (platform env vars, 1Password, Doppler, other):

Appendix: Proposed defaults for POC (edit as needed)
- Store raw emails encrypted (field-level envelope encryption) and expose only HMAC hashes publicly (proposed default).
- Use single-region US or EU for POC with clear migration plan to regional isolation (proposed default).
- Moderation: cheap classifier first-pass, escalate to stronger model for borderline cases (proposed default).
- Right-of-reply for verified recruiters within 7 days of a new review (proposed default).
- Takedown SLA: 72h standard, 24h urgent on verified identity (proposed default).
- Retention: 1 year for PII and logs in POC, subject to DSR deletion (proposed default).
- Logging: redact emails/IPs; store only hashes; structured logs only (proposed default).

