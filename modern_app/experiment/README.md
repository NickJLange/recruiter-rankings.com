# RR-14: isolated, non-release experiment

Base: `NickJLange/recruiter-rankings.com` `rewrite/next-foundation`, commit `ce14dafa3664a797015f10528117317939dcb4a2`. This directory is deliberately not wired to any Next route. It tests ordinary callable TypeScript functions and the existing Rails-derived SQL schema, not an HTTP application or production implementation. Never connect it to real identities or production data. Synthetic actor roles are caller assertions and are trivially forgeable; they are not authentication or authorization suitable for deployment.

## Clean rerun

Example on a disposable Debian 13 machine with Node 26.13.1, npm 10.9.11, PostgreSQL 17 and sudo. Use a new throwaway cluster, not an existing installation: this changes the local postgres password and the tests TRUNCATE tables in the named database. Obtain the supplied patch separately and run these commands from a scratch directory:

```sh
git clone https://github.com/NickJLange/recruiter-rankings.com.git rr14
cd rr14
git checkout -b experiment/rr-14 ce14dafa3664a797015f10528117317939dcb4a2
git apply /path/to/rr14.patch
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-client
sudo pg_ctlcluster 17 main start
sudo -u postgres psql -qc "ALTER USER postgres PASSWORD 'postgres'"
sudo -u postgres createdb rr14_test
cd modern_app
npm ci --no-audit --no-fund
DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr14_test npm run db:setup
TEST_DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr14_test npm test
npm run lint
npm run typecheck
npm run build
```

The `*_test` database guard is required by the existing test helpers. Do not use a real or shared database. The schema load is not a production migration. PostgreSQL version and cluster start command may differ on other distributions.

## Contract and design choices

The test submits five synthetic candidates via `submit`, checks pending, denies candidate moderation, and uses `moderate` to approve and later remove the same fifth experience. Four approved contributors return only `{slug, displayName}`, with the synthetic recruiter's actual name, no count or scores. A repeat submission is rejected, including concurrent submissions. To exercise dirty legacy data, the test creates a duplicate *pending* record directly; the moderator function approves it, and the anonymous query still sees four contributors. At five distinct contributors the output has count 5, overall 3 and responsiveness 3. Editing the fifth record returns it to pending and hides all aggregates; reapproval restores the aggregate at 2.8 and moderator removal hides it again. Unauthorized edits and removal are rejected.

The experiment uses a recruiter-row transaction lock to serialize submissions through this interface. For each recruiter and contributor, the highest experience ID is treated as current before filtering for approval. A pending or removed current record therefore suppresses the older one; reapproval makes only the current one eligible. Each category requires scores from five eligible contributors, and only one metric per selected record and category is used (the highest metric ID for legacy duplicates). This is an explicit experimental ordering policy, not a schema-enforced revision model. It does not enforce uniqueness against writers outside this interface, and physical deletion of the current row could revive an older one; a real data migration, uniqueness policy and contributor-level lifecycle remain necessary. The threshold alone also does not prevent inference by comparing successive snapshots.

The added regression cases first ran against the original patch and failed 3/5: both edit and removal exposed count 5 and average 3 from a revived duplicate, and four contributors plus a duplicate metric exposed clarity 2.2 while a one-contributor category exposed 5. After the fix, both return the named listing without aggregate; the category test omits both sparse categories and then publishes clarity at 3 after a fifth distinct approved contribution. Run the focused cases with `TEST_DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr14_test npx vitest run experiment/reviews.test.ts --reporter=verbose`.

Named synthetic listings implement RR-14's new contract, deliberately differing from the existing Next rule that masks names. No existing route was changed. The actual Next profile continues to mask names, expose subthreshold counts, and count rows, so this experiment is not evidence that any public page meets the contract.

## Comparison and limitations

This slice adds a callable implementation and database test without a new dependency or production schema migration. It reuses the existing interaction/experience/metric schema but adds transaction, validation, moderation and distinct-aggregation code outside the actual app. This does not quantify total Next implementation effort: real schema ownership, identity verification, role trust, concurrency across all writers, audit logging, privacy, deletion, UI, HTTP, caching, operations, recovery and migration remain. The RR-3 audit found Rails submission and legacy moderation use different records and found unsafe reads; clean-room has no comparable implementation. Neither alternative was implemented here, so no comparative effort or cost conclusion can be made. RR-3's illustrative shared hosting estimate is not a measured cost of this experiment. Independent rerun and audit remain required; passing this test does not select a baseline or authorize a release.
