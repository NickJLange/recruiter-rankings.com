# RR-10 browser-local preview experiment

This separate Next application is fictional and database-free. It does not change the real-database orb preview or production application. Four fixed approved fictional contributors and one simulated contribution per target illustrate pending, approval, removal, and separate overall/category thresholds. It does not establish authentication, shared public ratings, privacy, or backend security.

State is editable localStorage scoped to this browser profile and preview origin. Tabs in the same profile and origin share state and can overwrite or reset it; separate profiles/origins do not. Do not enter personal data. Reset removes only the chosen target's namespaced value. Concurrent tabs are not a transactional database.

## Local verification

Start from `NickJLange/recruiter-rankings.com` at `ce14dafa3664a797015f10528117317939dcb4a2`, apply the complete candidate patch, and run from the repository root:

```sh
cd modern_app
npm ci --no-audit --no-fund
NEXT_TELEMETRY_DISABLED=1 ./node_modules/.bin/next build rr10-browser-preview
./node_modules/.bin/eslint rr10-browser-preview/app rr10-browser-preview/next.config.mjs
./node_modules/.bin/tsc --noEmit -p rr10-browser-preview/tsconfig.json
./node_modules/.bin/vitest run rr10-browser-preview/app/simulation.test.ts
RR10_BROWSER_PREVIEW=enabled ./node_modules/.bin/next start rr10-browser-preview --hostname 127.0.0.1 --port 31587
```

The opt-in is a server runtime configuration, not authentication. Missing, empty, or wrong values return 404 for the application pages. There is no sitemap, canonical host, database variable or submission endpoint. Static framework assets and fictional source are not confidential.

For a dedicated Render **web service**, build from the repository root with `cd modern_app && npm ci --no-audit --no-fund && NEXT_TELEMETRY_DISABLED=1 ./node_modules/.bin/next build rr10-browser-preview`; start with `cd modern_app && ./node_modules/.bin/next start rr10-browser-preview --hostname 0.0.0.0 --port "$PORT"`; set only `RR10_BROWSER_PREVIEW=enabled` as the nonsecret application setting. Use free compute and manual PR previews on a newly created, dedicated demo base, never on an existing service; do not attach env groups, database URLs, secrets, domains, or production hooks. Only reviewed trusted PR heads and subsequent pushes may execute in previews. Inspect inherited effective settings and workspace usage/spend controls before creating a service.

Static export would remove the current server-runtime gate, so is not equivalent without a separately reviewed change to that requirement. No Render deployment has been verified.
