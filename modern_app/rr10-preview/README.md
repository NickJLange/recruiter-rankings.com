# RR-10 synthetic preview

This separate Next application is an experiment, not a release. It uses fictional fixtures and the RR-8 aggregate interface. The optional shared simulated feedback workspace has no sign-in and must never be connected to real data. Without its explicit opt-in and dedicated database checks, its mutation route returns 404. The existing application and its routes are not served by this preview.

## Shared synthetic moderation workspace

Use a new, isolated PostgreSQL 17 cluster, not an existing server. The demo checks the local address, dedicated port and database name, configured data directory, and a fixture marker. These are operational guardrails, not authentication or proof against a deliberately misconfigured local server. Anyone with access to the portal can play either role and reset the shared fixture; never use personal or production data. Overall and at least one dimension must be scored. All other dimensions may be N/A. Reset deletes only the fixed synthetic fifth contributor's scenario data; the fixture is seeded with four approved contributions per target.

Example from the repository root on a disposable machine with PostgreSQL 17 binaries and Node installed. The data directory must not exist already:

```sh
git checkout -b experiment/rr10-demo ce14dafa3664a797015f10528117317939dcb4a2
git apply /path/to/full-candidate.patch
cd modern_app && npm ci --no-audit --no-fund && cd ..
export RR10_DEMO_DATA_DIR="$PWD/.amp/in/orb-backup/rr10-demo-pg"
mkdir -p "$RR10_DEMO_DATA_DIR"
/usr/lib/postgresql/17/bin/initdb -D "$RR10_DEMO_DATA_DIR" --auth-local=trust --auth-host=trust
# Start postgres in a separate terminal or as a supervised service:
/usr/lib/postgresql/17/bin/postgres -D "$RR10_DEMO_DATA_DIR" -h 127.0.0.1 -p 55439 -k "$RR10_DEMO_DATA_DIR"
```

In a second terminal from the same checkout:

```sh
export RR10_DEMO_DATA_DIR="$PWD/.amp/in/orb-backup/rr10-demo-pg"
export DATABASE_URL=postgres://YOUR_LOCAL_USER@127.0.0.1:55439/rr10_moderation_demo
createdb -h 127.0.0.1 -p 55439 rr10_moderation_demo
npm --prefix modern_app run db:setup
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f modern_app/rr8/schema.sql -f modern_app/rr10-preview/demo-fixtures.sql
cd modern_app
NEXT_TELEMETRY_DISABLED=1 ./node_modules/.bin/next build rr10-preview
RR10_SYNTHETIC_DEMO=enabled RR10_PREVIEW_ORIGIN=https://YOUR-EXACT-PORTAL-ORIGIN ./node_modules/.bin/next start rr10-preview --hostname 0.0.0.0 --port 31583
```

Set the origin to the exact externally visible origin, without a trailing slash. Start with the origin unset until the portal URL is known; mutations reject requests until it is set. A portal is network-accessible. The mutation route requires same-origin requests and validates fixed targets, actors, actions, scores and dimension names. It does not provide real authorization, CSRF tokens, anti-abuse controls, audit infrastructure or production readiness. Existing previews must use separate builds and databases.

To exercise both targets through HTTP, run `RR10_PREVIEW_ORIGIN=https://YOUR-EXACT-PORTAL-ORIGIN node modern_app/rr10-preview/demo-check.mjs` from the repository root. This resets both shared scenarios before and after its checks. It verifies pending suppression, concurrent duplicates, approval and removal; it is not a security audit.

## Clean disposable setup

Start from `NickJLange/recruiter-rankings.com` revision `ce14dafa3664a797015f10528117317939dcb4a2`, apply the complete candidate patch, and install dependencies with `npm ci` in `modern_app`. Provision a disposable local PostgreSQL instance and create an empty `rr10_preview` database. The examples below assume a local PostgreSQL user `postgres` with password `postgres`; use only disposable credentials and data.

From the repository root:

```sh
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr10_preview
# Use the exact preview portal origin at build and server startup; omit its trailing slash.
export RR10_PREVIEW_ORIGIN=https://YOUR-PORTAL-ORIGIN
npm --prefix modern_app run db:setup
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f modern_app/rr8/schema.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f modern_app/rr10-preview/fixtures.sql
cd modern_app
NEXT_TELEMETRY_DISABLED=1 ./node_modules/.bin/next build rr10-preview
```

In an Amp orb, start a supervised preview from the repository root, using the absolute checkout path for `--cwd`:

```sh
amp orb service start rr10-preview --command 'DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr10_preview RR10_PREVIEW_ORIGIN=https://YOUR-PORTAL-ORIGIN NEXT_TELEMETRY_DISABLED=1 ./node_modules/.bin/next start rr10-preview --hostname 0.0.0.0 --port "$PORT"' --cwd "$PWD/modern_app" --port 31581 --portal
```

Use the exact portal URL printed by that command as `RR10_PREVIEW_ORIGIN`; if it was not known at build time, rebuild and restart with that value. The fallback is specific to the original experiment portal, not a production domain. To exercise the HTTP threshold sequence against this disposable database:

```sh
DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr10_preview PREVIEW_URL='https://YOUR-PORTAL-URL/' NODE_USE_SYSTEM_CA=1 node modern_app/rr10-preview/verify.mjs
```

The verifier directly changes two synthetic fixture rows through SQL, not the moderator application interface. It leaves those rows removed, and leaves other rated and unrated listings available. Never point it at any non-disposable database. The portal is network-accessible: use fictional data only. Browser inspection and the RR-8 test suite provide additional checks; this verifier alone does not establish a production privacy or security guarantee. Authentication, real data, restore/deletion guarantees, operational controls and the rest of RR-10 remain out of scope.

For a callable-interface lifecycle check which creates and removes separate synthetic targets and users, run `DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr10_preview PREVIEW_URL='https://YOUR-PORTAL-URL/' NODE_USE_SYSTEM_CA=1 node modern_app/rr10-preview/lifecycle-check.mjs`. Its actor roles are test inputs, not authenticated identities. The directory supports name search only; joined filters are not implemented. History navigation deliberately reloads to avoid Next's stale back/forward page payload; an already-open page is not automatically updated when moderation occurs.
