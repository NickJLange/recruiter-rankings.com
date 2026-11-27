// Run only against the disposable preview database and its running preview.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { createServer } = require('vite');
const base = process.env.PREVIEW_URL;
if (!base || !process.env.DATABASE_URL?.endsWith('/rr10_preview')) throw new Error('Disposable rr10_preview DATABASE_URL and PREVIEW_URL required');
const vite = await createServer({ root: fileURLToPath(new URL('..', import.meta.url)), server: { middlewareMode: true }, appType: 'custom' });
const { default: pool } = await vite.ssrLoadModule('/src/lib/db.ts');
const { submit, submitFirm, moderate, edit } = await vite.ssrLoadModule('/rr8/reviews.ts');
const token = `rr10-check-${process.pid}-${Date.now()}`;
const q = (...args) => pool.query(...args);
let firm, recruiter;
let users = [];
try {
  firm = Number((await q('INSERT INTO companies (name, created_at, updated_at) VALUES ($1, now(), now()) RETURNING id', [`${token} Firm`])).rows[0].id);
  recruiter = Number((await q('INSERT INTO recruiters (name, public_slug, created_at, updated_at) VALUES ($1, $2, now(), now()) RETURNING id', [`${token} Recruiter`, token])).rows[0].id);
  users = (await q(`INSERT INTO users (email_hmac, role, created_at, updated_at)
    SELECT $1 || '-' || n, CASE WHEN n = 6 THEN 'moderator' ELSE 'candidate' END, now(), now()
    FROM generate_series(1, 6) n RETURNING id`, [token])).rows.map(row => Number(row.id));
  const moderator = { userId: users[5], role: 'moderator' };
  const last = [];
  for (let i = 0; i < 5; i++) {
    const actor = { userId: users[i], role: 'candidate' };
    const input = { rating: 4, dimensions: i === 4 ? { communication: 4 } : { communication: 4, private_sparse: 3 } };
    for (const id of [await submitFirm(actor, firm, input), await submit(actor, recruiter, input)]) {
      if (i < 4) await moderate(moderator, id, 'approve'); else last.push(id);
    }
  }
  async function check(stage, rated) {
    for (const path of [`/firm/${firm}`, `/recruiter/${token}`]) {
      const res = await fetch(new URL(path, base), { cache: 'no-store' });
      const html = await res.text();
      assert.equal(res.status, 200);
      assert.ok(html.includes(rated ? 'OVERALL SCORE' : 'Getting the full picture'));
      assert.equal(html.includes('private_sparse'), false);
      assert.equal(html.includes(`${token}-5`), false);
    }
    const search = await (await fetch(new URL(`/?q=${encodeURIComponent(token)}`, base))).text();
    assert.ok(search.includes(`${token} Firm`) && search.includes(`${token} Recruiter`));
    assert.ok(!search.includes('private_sparse') && !search.includes(`${token}-5`));
    console.log(`${stage}: both profiles and mixed name search passed`);
  }
  await check('four', false);
  for (const id of last) await moderate(moderator, id, 'approve');
  await check('five', true);
  for (const id of last) await edit({ userId: users[4], role: 'candidate' }, id, { rating: 5, dimensions: { communication: 5 } });
  await check('edited pending', false);
  for (const id of last) await moderate(moderator, id, 'approve');
  await check('reapproved', true);
  for (const id of last) await moderate(moderator, id, 'remove');
  await check('removed', false);
} finally {
  if (users.length) {
    await q('DELETE FROM rr8_moderation_decisions WHERE moderator_id = ANY($1::bigint[])', [users]);
    await q('DELETE FROM rr8_submissions WHERE contributor_id = ANY($1::bigint[])', [users]);
    await q('DELETE FROM rr8_reviews WHERE slot_id IN (SELECT id FROM rr8_slots WHERE contributor_id = ANY($1::bigint[]))', [users]);
    await q('DELETE FROM rr8_slots WHERE contributor_id = ANY($1::bigint[])', [users]);
    await q('DELETE FROM users WHERE id = ANY($1::bigint[])', [users]);
  }
  if (recruiter) await q('DELETE FROM recruiters WHERE id = $1', [recruiter]);
  if (firm) await q('DELETE FROM companies WHERE id = $1', [firm]);
  await pool.end(); await vite.close();
}
