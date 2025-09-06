# Recruiter-Rankings: Gameplan Draft Questionnaire

Instructions
- Provide short, concrete answers (bullets are fine).
- Assume emails are stored but never publicly displayed unless stated otherwise.
- POC can use synthetic data unless you explicitly choose real data.

Open contradictions and decisions to clarify
- Public PII lists recruiter email, but later states emails should never appear. Clarify: store email but never display publicly?
  Correct. Store email encrypted, display only HMAC hash publicly.
- LinkedIn challenge token may be difficult without partner API access. Are you OK with non-API verification alternatives?
  Yes, the users will add a token section to their LinkedIn Profile that we will specify. The token space should be large enough to avoid collisions.
- DB sharding: clarify the sharding dimension (geography, company, recruiter-id hash, or other).
We should shard on geography and company, ideally focusing on the home of the recruiter.
- Capturing decoded identities for future use risks purpose creep. Confirm intent and consent model.
   yes
- Domain: recruiterrankings.com (no hyphen) vs recruiter-rankings.com (hyphen). Which is canonical?
    recruiter-rankings.com (hyphen)

1) Vision, scope, and audience
- Primary launch regions (e.g., US, EU, UK, other):
US
- Initial primary user (candidates or companies buying reports):
Me
- Secondary users:
Kenta Lange
- Recruiter types in scope (in-house, agency, sourcers, coordinators):
all
- Individual vs agency-level ratings:
We should support both and trend over time
- Minimum validation for a review (e.g., confirmed interaction within last 12 months, evidence type):
For now, no evidence but let's leave something for the future.
- POC success metrics (e.g., 100 verified reviews, 500 candidate signups, 50 recruiter profiles claimed):
100 verified reviews, 500 candidate signups, 50 recruiter profiles claimed

2) Value proposition and content model
- Public directory with aggregated, de-identified metrics? (yes/no):
public with de-identified metrics
- Right-of-reply for recruiters after verification? (yes/no):
yes, SLA of 7 days - we try to hold off posting until we can make sure no slander.
- Standardized question dimensions (pick top 6–8 and add any):
  - Responsiveness
  - Clarity/accuracy of role description
  - Understanding of candidate needs and special circumstances
  - Fairness and inclusivity
  - Timeline management
  - Feedback quality
  - Professionalism/respect
  - Job-role match quality
  - Outcome (screen/reject/offer)
- Rating format (1–5 stars, NPS, yes/no, weighted composite):
1-5 stars
- Show distribution by hiring stages? (yes/no). If yes, confirm stages:
  - Sourced → Recruiter Screen → HM Screen → Onsite/Loop → Offer → Decision
 no, not for now
- Company visibility: hide companies < 50 staff entirely, or show as Small company bucket?:
Small company bucket
- Company-to-company comparisons (allowed/not allowed). If allowed, guardrails:
yes, guardrails: only aggregated metrics, no PII
- Browser extension in POC? (yes/no). If yes, flows to include (e.g., capture from Gmail/LinkedIn, quick-rate):
no
3) Monetization and pricing
- Prioritize near-term revenue: SEO/ads vs B2B reports vs other:
SEO
- Private report buyers (talent leadership, HR, procurement, other):
Talent leadership, HR
- Signals included in paid reports (choose):
  - Time-to-first-response, response rate
  - Benchmarks vs peers
  - candidate happy with process
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
default to takedown
- Takedown SLA targets (e.g., 72h standard, 24h urgent):
7 days, urgent 3 days
- Right-of-reply process for recruiters (yes/no). If yes, constraints:
yes, only if particularly slanderous
- Geographic compliance scope for POC (GDPR, UK GDPR, CCPA/CPRA, PIPEDA, other):
GPDR
- Data subject requests (access, deletion, correction) handled in POC? (yes/no):
yes
- POC data type (synthetic-only, real with consent, mixed):
synthetic-only
- Moderation approach (cheap model + escalation). Budget per 1k items and target latency:
cheap!

5) Identity and verification
- LinkedIn API access/partner status available? (yes/no):
no
- If no, acceptable user verification methods (choose):
  - LinkedIn profile challenge (temporary code in Website/Featured)
- Recruiter verification (choose):
  - LinkedIn profile challenge (temporary code in Website/Featured)
- Challenge token TTL and re-verification frequency:
- Fraud prevention thresholds (e.g., number of reviews per account/day, minimum account age):
yes - 10

6) Data security and privacy
- Emails: store HMAC(email, secret pepper) for public refs and encrypt raw email at rest? (yes/no):
yes, I'll put in the key at startup for decode. We want to support two levels of keys - one for the data, and a key-for-the key that we can rotate periodically without needing to change the data encryption.
- Additional metadata to store (IP, user agent, timestamps, geo) and retention:
- PII retention defaults for POC (e.g., 180 days, 1 year):
180 days
- Unstructured review text retention and redaction policy:
- Access roles and permissions (anonymous, candidate, recruiter, moderator, admin) and visibility per role:
- Anonymous: can view aggregated metrics only
- Candidate: can submit reviews, view aggregated metrics
- Recruiter: can claim profile, respond to reviews, view aggregated metrics
- Moderator: can review flagged content, manage takedown requests
- Admin: full access to all data and settings
- Cross-border strategy for POC (single region now, regional isolation later):
single region
- Takedown/DSR workflow (email-only, web form, both) and identity proof required:
email only
- Logging and observability redaction (avoid storing emails/IPs in logs; mask by default):
yes
- Threats to prioritize (rank): account takeover, scraping/enum, libel injection, spam/fake accounts, insider access, data exfiltration:
that order.

7) Technical stack and constraints
- Preferred stack (TypeScript, Next.js/SvelteKit/Remix, Node/Deno):
Jekyll / Ruby on Rails
- Database preference (Postgres via Neon/Supabase, MySQL via PlanetScale, SQLite via Turso/Cloudflare D1):
Postgres
- Hosting region(s) for POC:
US
- Monthly budget target ($0–$5 typical):
$5
- Performance targets (p95 latency, cold starts acceptable?):
p95 < 500ms, cold starts acceptable
- Observability (basic logs only, plus metrics, plus tracing):
metrics and tracing
- Feature flags and config management approach:
yes
- Moderation model choice (open-source small model vs hosted cheap LLM) and provider shortlist:
hosted cheap LLM, e.g. OpenAI or Anthropic

8) Sharding and scalability
- Sharding dimension long-term (geography, company, recruiter-id hash, tenant):
geography, company
- For POC, is logical partitioning enough (row-level region tags + partial indexes)? (yes/no):
yes
- Expected 6-month scale (number of recruiter profiles, companies, reviews):
100

9) Hosting for POC (pick one or propose)
- Options shortlist:
  - Railway (Free dev) + Postgres
  - Render (free web service) + managed DB
- Data residency constraints that affect choice:
- Secrets management approach (platform env vars, 1Password, Doppler, other):
platform env vars

Appendix: Proposed defaults for POC (edit as needed)
- Store raw emails encrypted (field-level envelope encryption) and expose only HMAC hashes publicly (proposed default).
- Use single-region US or EU for POC with clear migration plan to regional isolation (proposed default).
- Moderation: cheap classifier first-pass, escalate to stronger model for borderline cases (proposed default).
- Right-of-reply for verified recruiters within 7 days of a new review (proposed default).
- Takedown SLA: 72h standard, 24h urgent on verified identity (proposed default).
- Retention: 1 year for PII and logs in POC, subject to DSR deletion (proposed default).
- Logging: redact emails/IPs; store only hashes; structured logs only (proposed default).
