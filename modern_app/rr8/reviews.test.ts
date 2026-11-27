import { readFile } from 'node:fs/promises';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { insertCompany, insertRecruiter, pool, resetDb } from '../src/test/db';
import { anonymousFirmListing, anonymousListing, edit, moderate, permanentlyDelete, submit, submitFirm, type Actor } from './reviews';
let recruiter: number;
let candidates: Actor[];
let moderator: Actor;
const score = (n: number) => ({ rating: n, dimensions: { responsiveness: n } });
const hidden = { slug: 'RR-0001', displayName: 'Synthetic Name' };
beforeAll(async () => {
  await pool.query('DROP TABLE IF EXISTS rr8_submissions, rr8_moderation_decisions, rr8_metrics, rr8_reviews, rr8_slots CASCADE');
  await pool.query(await readFile(new URL('./schema.sql', import.meta.url), 'utf8'));
});
beforeEach(async () => {
  await resetDb();
  recruiter = await insertRecruiter({ name: 'Synthetic Name', slug: 'RR-0001' });
  const users = await pool.query(`INSERT INTO users (email_hmac, role, created_at, updated_at)
    SELECT 'rr8-synthetic-' || n, CASE WHEN n = 6 THEN 'moderator' ELSE 'candidate' END, now(), now()
    FROM generate_series(1, 6) n RETURNING id`);
  candidates = users.rows.slice(0, 5).map(row => ({ userId: Number(row.id), role: 'candidate' }));
  moderator = { userId: Number(users.rows[5].id), role: 'moderator' };
});
afterAll(() => pool.end());
describe('RR-8 owned review persistence', () => {
  it('isolates named firms and recruiter aggregates despite colliding target IDs', async () => {
    const firm = await insertCompany('Synthetic Firm');
    expect(firm).toBe(recruiter);
    const firmHidden = { id: firm, displayName: 'Synthetic Firm' };
    expect(await anonymousFirmListing(firm)).toEqual(firmHidden);
    const firmIds: number[] = [];
    let lastRecruiterReview = 0;
    for (let i = 0; i < 5; i++) {
      const recruiterReview = await submit(candidates[i], recruiter, score(1));
      if (i < 4) await moderate(moderator, recruiterReview, 'approve');
      else lastRecruiterReview = recruiterReview;
      const dimensions: Record<string, number> = { responsiveness: 5 };
      if (i < 4) dimensions.clarity = 4;
      const id = await submitFirm(candidates[i], firm, { rating: 5, dimensions });
      firmIds.push(id);
      expect((await pool.query('SELECT status FROM rr8_reviews WHERE id = $1', [id])).rows[0].status).toBe('pending');
      await expect(submitFirm(candidates[i], firm, score(3))).rejects.toThrow('Duplicate');
      await expect(moderate(candidates[i], id, 'approve')).rejects.toThrow('Forbidden');
      if (i === 4) {
        await moderate(moderator, lastRecruiterReview, 'approve');
        expect(await anonymousFirmListing(firm)).toEqual(firmHidden);
        await edit(candidates[4], lastRecruiterReview, score(1));
      }
      await moderate(moderator, id, 'approve');
    }
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
    expect(await anonymousFirmListing(firm)).toEqual({ ...firmHidden, count: 5, average: 5, dimensions: { responsiveness: 5 } });
    await moderate(moderator, lastRecruiterReview, 'approve');
    expect(await anonymousListing('RR-0001')).toEqual({ ...hidden, count: 5, average: 1, dimensions: { responsiveness: 1 } });
    expect(await anonymousFirmListing(firm)).toEqual({ ...firmHidden, count: 5, average: 5, dimensions: { responsiveness: 5 } });
    await expect(edit(candidates[1], firmIds[4], score(2))).rejects.toThrow('forbidden');
    await edit(candidates[4], firmIds[4], { rating: 4, dimensions: { responsiveness: 4, clarity: 4 } });
    expect(await anonymousFirmListing(firm)).toEqual(firmHidden);
    await moderate(moderator, firmIds[4], 'approve');
    expect(await anonymousFirmListing(firm)).toEqual({ ...firmHidden, count: 5, average: 4.8, dimensions: { responsiveness: 4.8, clarity: 4 } });
    const count = await pool.query('SELECT count(*)::int AS count FROM rr8_moderation_decisions WHERE review_id = $1', [firmIds[4]]);
    const missingModerator: Actor = { userId: 999999999, role: 'moderator' };
    await expect(moderate(missingModerator, firmIds[4], 'remove')).rejects.toMatchObject({ code: '23503' });
    expect((await pool.query('SELECT status FROM rr8_reviews WHERE id = $1', [firmIds[4]])).rows[0].status).toBe('approved');
    expect((await pool.query('SELECT count(*)::int AS count FROM rr8_moderation_decisions WHERE review_id = $1', [firmIds[4]])).rows[0]).toEqual(count.rows[0]);
    await moderate(moderator, firmIds[4], 'remove');
    expect(await anonymousFirmListing(firm)).toEqual(firmHidden);
    await expect(edit(candidates[4], firmIds[4], score(2))).rejects.toThrow('forbidden');
    await expect(moderate(moderator, firmIds[4], 'approve')).rejects.toThrow('Invalid transition');
    expect((await pool.query('SELECT decision FROM rr8_moderation_decisions WHERE review_id = $1 ORDER BY id', [firmIds[4]])).rows).toEqual([{ decision: 'approve' }, { decision: 'approve' }, { decision: 'remove' }]);
    expect(await anonymousListing('RR-0001')).toEqual({ ...hidden, count: 5, average: 1, dimensions: { responsiveness: 1 } });
  });

  it('enforces a cross-target rolling submission limit under concurrency and at window edges', async () => {
    const firms: number[] = [];
    for (let i = 0; i < 12; i++) firms.push(await insertCompany(`Firm ${i}`));
    await submit(candidates[0], recruiter, score(3));
    await expect(submit(candidates[0], recruiter, score(3))).rejects.toThrow('Duplicate');
    await expect(submitFirm(candidates[0], 999999999, score(3))).rejects.toMatchObject({ code: '23503' });
    expect((await pool.query('SELECT count(*)::int AS count FROM rr8_submissions WHERE contributor_id = $1', [candidates[0].userId])).rows[0].count).toBe(1);
    const results = await Promise.allSettled(firms.slice(0, 10).map(id => submitFirm(candidates[0], id, score(4))));
    expect(results.filter(result => result.status === 'fulfilled')).toHaveLength(9);
    expect(results.filter(result => result.status === 'rejected')).toHaveLength(1);
    expect((await pool.query('SELECT count(*)::int AS count FROM rr8_submissions WHERE contributor_id = $1', [candidates[0].userId])).rows[0].count).toBe(10);
    await expect(submitFirm(candidates[0], firms[11], score(3))).rejects.toThrow('Submission limit');
    await pool.query(`UPDATE rr8_submissions SET submitted_at = clock_timestamp() - interval '24 hours' + interval '10 seconds'
      WHERE id = (SELECT min(id) FROM rr8_submissions WHERE contributor_id = $1)`, [candidates[0].userId]);
    await expect(submitFirm(candidates[0], firms[11], score(3))).rejects.toThrow('Submission limit');
    await pool.query(`UPDATE rr8_submissions SET submitted_at = clock_timestamp() - interval '24 hours' - interval '1 second'
      WHERE id = (SELECT min(id) FROM rr8_submissions WHERE contributor_id = $1)`, [candidates[0].userId]);
    await submitFirm(candidates[0], firms[11], score(3));
    await expect(submitFirm(candidates[0], firms[10], score(3))).rejects.toThrow('Submission limit');
    await submitFirm(candidates[1], firms[10], score(3));
  });
  it('records exactly one private decision per successful moderation transition', async () => {
    const id = await submit(candidates[0], recruiter, score(3));
    const decisions = async () => (await pool.query(`SELECT review_id::int, moderator_id::int, decision, decided_at
      FROM rr8_moderation_decisions ORDER BY id`)).rows;
    await expect(moderate(candidates[0], id, 'approve')).rejects.toThrow('Forbidden');
    expect(await decisions()).toEqual([]);
    await moderate(moderator, id, 'approve');
    const approved = await decisions();
    expect(approved).toHaveLength(1);
    expect(approved[0]).toEqual({ review_id: id, moderator_id: moderator.userId, decision: 'approve', decided_at: expect.any(Date) });
    await expect(moderate(moderator, id, 'approve')).rejects.toThrow('Invalid transition');
    await expect(moderate(candidates[0], id, 'remove')).rejects.toThrow('Forbidden');
    expect(await decisions()).toEqual(approved);
    await moderate(moderator, id, 'remove');
    const removed = await decisions();
    expect(removed).toHaveLength(2);
    expect(removed[0]).toEqual(approved[0]);
    expect(removed[1]).toEqual({ review_id: id, moderator_id: moderator.userId, decision: 'remove', decided_at: expect.any(Date) });
    await expect(moderate(moderator, id, 'remove')).rejects.toThrow('Invalid transition');
    await expect(moderate(moderator, id, 'approve')).rejects.toThrow('Invalid transition');
    expect(await decisions()).toEqual(removed);
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
    await permanentlyDelete(moderator, id);
    expect(await decisions()).toEqual(removed);
  });

  it('rolls back the status change if writing the decision fails', async () => {
    const id = await submit(candidates[0], recruiter, score(3));
    const missingModerator: Actor = { userId: 999999999, role: 'moderator' };
    await expect(moderate(missingModerator, id, 'approve')).rejects.toMatchObject({ code: '23503' });
    expect((await pool.query('SELECT status FROM rr8_reviews WHERE id = $1', [id])).rows[0].status).toBe('pending');
    expect((await pool.query('SELECT id FROM rr8_moderation_decisions')).rowCount).toBe(0);
    await moderate(moderator, id, 'approve');
    await expect(moderate(missingModerator, id, 'remove')).rejects.toMatchObject({ code: '23503' });
    expect((await pool.query('SELECT status FROM rr8_reviews WHERE id = $1', [id])).rows[0].status).toBe('approved');
    expect((await pool.query('SELECT decision FROM rr8_moderation_decisions')).rows).toEqual([{ decision: 'approve' }]);
  });

  it('permanently deletes current content without reviving history, including repeated deletion', async () => {
    const ids = [];
    for (const candidate of candidates) {
      const id = await submit(candidate, recruiter, score(3));
      ids.push(id);
      await moderate(moderator, id, 'approve');
    }
    // Represent imported historical data; moderation remains through the callable interface.
    const old = ids[0];
    const slot = await pool.query('SELECT id FROM rr8_slots WHERE current_review_id = $1', [old]);
    const replacement = await pool.query("INSERT INTO rr8_reviews (slot_id, rating, status) VALUES ($1, 5, 'pending') RETURNING id", [slot.rows[0].id]);
    const current = Number(replacement.rows[0].id);
    await pool.query("INSERT INTO rr8_metrics (review_id, dimension, score) VALUES ($1, 'responsiveness', 5)", [current]);
    await pool.query('UPDATE rr8_slots SET current_review_id = $1 WHERE id = $2', [current, slot.rows[0].id]);
    await moderate(moderator, current, 'approve');
    expect(await anonymousListing('RR-0001')).toMatchObject({ count: 5, average: 3.4 });
    await expect(permanentlyDelete(candidates[0], current)).rejects.toThrow('Forbidden');
    await permanentlyDelete(moderator, current);
    await permanentlyDelete(moderator, current);
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
    expect((await pool.query('SELECT id FROM rr8_reviews WHERE id = $1', [current])).rowCount).toBe(0);
    expect((await pool.query('SELECT review_id FROM rr8_metrics WHERE review_id = $1', [current])).rowCount).toBe(0);
    expect((await pool.query('SELECT current_review_id FROM rr8_slots WHERE id = $1', [slot.rows[0].id])).rows[0].current_review_id).toBeNull();
    expect((await pool.query('SELECT id FROM rr8_reviews WHERE id = $1', [old])).rowCount).toBe(1);
    await expect(submit(candidates[0], recruiter, score(5))).rejects.toThrow('Duplicate');
  });
  it('suppresses sparse dimensions and restores them at five distinct eligible contributors', async () => {
    const ids = [];
    for (let i = 0; i < 5; i++) {
      const dimensions: Record<string, number> = { responsiveness: i + 1 };
      if (i < 4) dimensions.clarity = i + 1;
      const id = await submit(candidates[i], recruiter, { rating: i + 1, dimensions });
      ids.push(id);
      if (i === 3) expect(await anonymousListing('RR-0001')).toEqual(hidden);
      await moderate(moderator, id, 'approve');
      if (i === 3) expect(await anonymousListing('RR-0001')).toEqual(hidden);
    }
    expect(await anonymousListing('RR-0001')).toEqual({ ...hidden, count: 5, average: 3, dimensions: { responsiveness: 3 } });
    await expect(edit(candidates[1], ids[4], score(4))).rejects.toThrow('forbidden');
    await edit(candidates[4], ids[4], { rating: 5, dimensions: { responsiveness: 5, clarity: 5 } });
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
    await moderate(moderator, ids[4], 'approve');
    expect(await anonymousListing('RR-0001')).toEqual({ ...hidden, count: 5, average: 3, dimensions: { responsiveness: 3, clarity: 3 } });
    await moderate(moderator, ids[4], 'remove');
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
  });
  it.each(['remove', 'delete'] as const)('serializes a concurrent edit and %s', async (action) => {
    const id = await submit(candidates[0], recruiter, score(3));
    await moderate(moderator, id, 'approve');
    const [edited, removed] = await Promise.allSettled([
      edit(candidates[0], id, score(4)),
      action === 'remove' ? moderate(moderator, id, 'remove') : permanentlyDelete(moderator, id),
    ]);
    expect(removed.status).toBe('fulfilled');
    if (edited.status === 'rejected') expect(edited.reason.message).toMatch(/not found or forbidden/i);
    const review = await pool.query('SELECT status FROM rr8_reviews WHERE id = $1', [id]);
    if (action === 'remove') expect(review.rows[0].status).toBe('removed');
    else expect(review.rowCount).toBe(0);
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
    await expect(edit(candidates[0], id, score(5))).rejects.toThrow('forbidden');
  });

  it.each([
    ['recruiter', 'edit'], ['recruiter', 'remove'], ['firm', 'edit'], ['firm', 'remove'],
  ] as const)('keeps %s removal terminal with %s queued first', async (kind, first) => {
    const id = kind === 'firm'
      ? await submitFirm(candidates[0], await insertCompany('Concurrent Firm'), score(3))
      : await submit(candidates[0], recruiter, score(3));
    await moderate(moderator, id, 'approve');
    const blocker = await pool.connect();
    const waitForBlocked = async (count: number) => {
      for (let attempt = 0; attempt < 200; attempt++) {
        const result = await pool.query(`SELECT count(*)::int AS count FROM pg_stat_activity
          WHERE datname = current_database() AND wait_event_type = 'Lock'
            AND query LIKE '%FOR UPDATE OF s%'`);
        if (result.rows[0].count >= count) return;
        await blocker.query('SELECT pg_sleep(0.01)');
      }
      throw new Error(`Expected ${count} waiting review operations`);
    };
    let editResult: Promise<PromiseSettledResult<void>> | undefined;
    let removeResult: Promise<PromiseSettledResult<void>> | undefined;
    try {
      await blocker.query('BEGIN');
      await blocker.query('SELECT id FROM rr8_slots WHERE current_review_id = $1 FOR UPDATE', [id]);
      const runEdit = () => edit(candidates[0], id, score(4)).then(() => ({ status: 'fulfilled' as const, value: undefined }), reason => ({ status: 'rejected' as const, reason }));
      const runRemove = () => moderate(moderator, id, 'remove').then(() => ({ status: 'fulfilled' as const, value: undefined }), reason => ({ status: 'rejected' as const, reason }));
      if (first === 'edit') editResult = runEdit();
      else removeResult = runRemove();
      await waitForBlocked(1);
      if (first === 'edit') removeResult = runRemove();
      else editResult = runEdit();
      await waitForBlocked(2);
      await blocker.query('COMMIT');
    } finally {
      await blocker.query('ROLLBACK');
      blocker.release();
    }
    const edited = await editResult;
    const removed = await removeResult;
    expect(removed?.status).toBe('fulfilled');
    expect(edited?.status).toBe(first === 'edit' ? 'fulfilled' : 'rejected');
    if (edited?.status === 'rejected') expect(edited.reason.message).toMatch(/not found or forbidden/i);
    expect((await pool.query('SELECT status, rating FROM rr8_reviews WHERE id = $1', [id])).rows[0]).toEqual({ status: 'removed', rating: first === 'edit' ? 4 : 3 });
    await expect(moderate(moderator, id, 'approve')).rejects.toThrow('Invalid transition');
    expect((await pool.query('SELECT status FROM rr8_reviews WHERE id = $1', [id])).rows[0].status).toBe('removed');
  });
});
