# RR-8 first bounded persistence pass — not release-ready

This is an isolated callable server-side slice, not a public route. Base: NickJLange `rewrite/next-foundation` at `ce14dafa3664a797015f10528117317939dcb4a2`. The retained `experiment/` directory is the RR-14 reference; the revised reference patch SHA-256 is `766dda7d194e1ef4c0f88e16274f4456eda5d419ace0a6020170aa93222fe4c7`. The new code is under `rr8/`; the SQL is a disposable test schema, **not a production migration**. All identities used here are synthetic and actor roles are caller assertions, not authentication.

## Clean rerun

Use a fresh disposable Debian 13 machine with Node 26.13.1, npm 10.9.11, PostgreSQL 17 and sudo. These commands change the disposable postgres password, and the tests truncate tables and drop RR-8 tables. Never run against a shared or real database.

```sh
git clone https://github.com/NickJLange/recruiter-rankings.com.git rr8
cd rr8
git checkout -b rr8-slice ce14dafa3664a797015f10528117317939dcb4a2
git apply /path/to/rr8-candidate.patch
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-client
sudo pg_ctlcluster 17 main start
sudo -u postgres psql -qc "ALTER USER postgres PASSWORD 'postgres'"
sudo -u postgres createdb rr8_test
cd modern_app
npm ci --no-audit --no-fund
DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr8_test npm run db:setup
TEST_DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr8_test npx vitest run rr8/reviews.test.ts --reporter=verbose
TEST_DATABASE_URL=postgres://postgres:postgres@localhost:5432/rr8_test npm test
npm run lint
npm run typecheck
NEXT_TELEMETRY_DISABLED=1 npm run build
```

The tests create and drop the RR-8 candidate tables themselves; the existing helper refuses a database name that does not end in `_test`. PostgreSQL 17 is required by the column-specific `ON DELETE SET NULL` foreign key used here.

## Evidence and scope

On the RR-14 reference, a temporary test submitted and approved five contributors, inserted a newer pending duplicate, approved it through moderation, then physically deleted it. Expected name/slug only; actual output was count 5, average 3 and responsiveness 3 because the older approval revived. That temporary failing test was removed; this output is the before evidence, not a claim that RR-14 itself was fixed.

The new path creates one durable slot per recruiter and contributor. The slot points to exactly one current review; the composite foreign key prevents cross-slot pointers and clears only the pointer when the current review is physically deleted. Metrics cascade away, and no read selects an older row. The unique slot remains after deletion and prevents resubmission in this bounded policy. Edit, moderation, and permanent deletion lock the same slot. The test creates a historical duplicate and sets the pointer as an import fixture; approvals use the callable interface. It verifies deletion twice, no restoration of the older record, named listing, deleted content, and duplicate rejection. Separate cases cover 4/5 overall and category thresholds, unauthorized edits, and concurrent edit versus moderation removal and permanent deletion. The concurrency test runs a race and asserts the allowed final states, not exhaustive scheduling or distributed failure.

The initial RR-8 candidate could read a stale joined review status after waiting for the slot lock. A controlled regression holds the slot lock, starts both callable operations in a chosen order, and observes each waiting in `pg_stat_activity` before releasing it. On the original candidate, edit-first passed but remove-first allowed the edit to succeed instead of rejecting it. The revised path first locks the slot, then reads review status in a new statement, and applies conditional status updates. Both controlled orderings now pass: edit-first leaves the edited rating removed; remove-first rejects the edit and leaves the original rating removed. Both reject reapproval and check persisted state. This test assumes the normal PostgreSQL READ COMMITTED isolation level; it is not exhaustive proof across other isolation levels or direct database writers.

Each successful callable approval or removal now inserts one private decision row in the same transaction as the status transition. It contains only its own ID, the review ID, the moderator user ID, the decision and a database timestamp; listings do not read it. The review ID deliberately has no foreign key so decisions remain after physical review deletion; the application supplies it only after successfully changing the existing current review. The moderator ID references users, so deleting a moderator is blocked while decisions refer to that user. Decisions and retained identifiers are sensitive: retention, access control, integrity enforcement, erasure and moderator deletion policy remain undecided. This is not an independently protected or immutable audit log, a deletion ledger, a record of failed attempts, or proof of a real moderator's identity.

The PostgreSQL tests check exactly one matching row per successful approval/removal, no extra rows for unauthorized or repeated attempts, no audit fields in the exact anonymous listing, and persistence of decisions after current-review deletion. A synthetic missing moderator ID triggers PostgreSQL foreign-key error 23503 on decision insertion after the attempted status update; both approval and removal tests confirm that the transaction rolls back status and does not add a decision. This tests that database error path only, not all storage failure modes.

## Firm targets and provisional rate limit

Firms use the existing `companies` rows and a separate nullable foreign key on the shared review slot; exactly one of recruiter or firm must be set. Uniqueness is per contributor and target type/ID, so a firm and recruiter may share an ID without sharing reviews. The same submission, edit, moderation, decision and aggregation lifecycle applies to both. Tests use a firm and recruiter both numbered 1, show that five approvals of one cannot unlock four of the other, check category suppression and release, and return the firm to name-only after edit or removal. Firm moderation decision write failure rolls back as for recruiters; controlled concurrent edit/removal tests run for both types.

The provisional synthetic policy permits **10 successful new submissions per contributor in a rolling 24 hours**, across both target types. A submission counts until its timestamp is at or before the cutoff; edits, failed submissions, moderation and removal do not consume another unit. A contributor row lock serializes the count and insertion in a transaction; the event is not removed by review deletion. Tests submit to one recruiter and ten firms concurrently (nine firm submissions succeed, one is denied), check that an event just inside the window still blocks and one outside permits submission, and show a different contributor is independent. The tests do not freeze the database clock or hit the exact cutoff instant; exact cutoff follows the strict `>` query. This is a provisional abuse control, not a trusted-identity, distributed-writer, IP or production rate policy. Events and retained slots carry privacy/retention obligations and backup rollback can reset limits. Schema and test fixtures here are disposable, not a migration.

## Restore requirements — not exercised

An old backup can restore deleted review content, an old current pointer and approvals, including earlier duplicates. Before **any** restored data serves reads or accepts writes, keep the service isolated and reconcile it against a durable, independently retained deletion ledger covering every deletion after the backup snapshot; reapply all physical deletions and clear affected pointers transactionally, validate referential integrity, and verify suppressed aggregates before reopening. A missing, incomplete, untrusted or older ledger must fail closed; never reconstruct current pointers from the latest surviving record. The ledger must survive the same failure domain and retention window as backups and be designed for the privacy obligations of storing deletion identifiers. Decide authenticated deletion authorization, identity minimization, ledger durability/retention, backup expiry and restore ownership before any production use. This candidate does not implement or test such a ledger, backup, restore, reconciliation, restore auditing or disaster recovery.

## Remaining RR-8 and release gaps

No real authentication, trusted identity/role boundary, production-grade rate controls, protected audit access or retention policy, production migration/schema ownership, legacy data import or duplicate reconciliation. Legacy public profile code is unchanged and still has known privacy flaws. No protection against privileged SQL rewriting pointers or audit records, hard deletion of slots, backup rollback, concurrent writes outside these APIs, or inference from successive aggregates. This is not proof of privacy, deletion compliance, deployment readiness, or completion of RR-8. Independent audit and a production design are required.
