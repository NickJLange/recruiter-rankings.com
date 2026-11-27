import { afterAll, beforeEach, describe, expect, it } from 'vitest';
import { insertRecruiter, pool, resetDb } from '../src/test/db';
import { anonymousListing, edit, moderate, submit, type Actor } from './reviews';

let recruiter: number;
let candidates: Actor[];
let moderator: Actor;
const score = (rating: number) => ({ rating, dimensions: { responsiveness: rating } });

beforeEach(async () => {
  await resetDb();
  recruiter = await insertRecruiter({ name: 'Synthetic Name', slug: 'RR-0001' });
  const users = await pool.query(`INSERT INTO users (email_hmac, role, created_at, updated_at)
    SELECT 'synthetic-' || n, CASE WHEN n = 6 THEN 'moderator' ELSE 'candidate' END, now(), now()
    FROM generate_series(1, 6) n RETURNING id, role`);
  candidates = users.rows.slice(0, 5).map((r) => ({ userId: Number(r.id), role: 'candidate' }));
  moderator = { userId: Number(users.rows[5].id), role: 'moderator' };
});
afterAll(() => pool.end());

describe('RR-14 synthetic callable experiment', () => {
  it('enforces moderation, distinct contributors, edit and removal through the application interface', async () => {
    const ids = [];
    for (let n = 0; n < 4; n++) {
      const id = await submit(candidates[n], recruiter, score(n + 1));
      ids.push(id);
      expect((await pool.query('SELECT status FROM experiences WHERE id = $1', [id])).rows[0].status).toBe('pending');
      await expect(moderate(candidates[n], id, 'approve')).rejects.toThrow('Forbidden');
      await moderate(moderator, id, 'approve');
    }
    const hidden = { slug: 'RR-0001', displayName: 'Synthetic Name' };
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
    await expect(submit(candidates[0], recruiter, score(5))).rejects.toThrow('Duplicate');
    // Legacy duplicate data must not unlock the aggregate even if the write guard was bypassed.
    const duplicate = await pool.query(`INSERT INTO interactions (recruiter_id, target_id, created_at, updated_at)
      VALUES ($1, $2, now(), now()) RETURNING id`, [recruiter, candidates[0].userId]);
    const duplicateExperience = await pool.query(`INSERT INTO experiences (interaction_id, rating, status, created_at, updated_at)
      VALUES ($1, 1, 'pending', now(), now()) RETURNING id`, [duplicate.rows[0].id]);
    await pool.query(`INSERT INTO review_metrics (experience_id, dimension, score, created_at, updated_at)
      VALUES ($1, 'responsiveness', 1, now(), now())`, [duplicateExperience.rows[0].id]);
    await moderate(moderator, Number(duplicateExperience.rows[0].id), 'approve');
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
    const fifth = await submit(candidates[4], recruiter, score(5));
    await moderate(moderator, fifth, 'approve');
    expect(await anonymousListing('RR-0001')).toEqual({ ...hidden, count: 5, average: 3, dimensions: { responsiveness: 3 } });
    await expect(edit(candidates[1], fifth, score(4))).rejects.toThrow('forbidden');
    await edit(candidates[4], fifth, score(4));
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
    await moderate(moderator, fifth, 'approve');
    expect(await anonymousListing('RR-0001')).toMatchObject({ count: 5, average: 2.8 });
    await expect(moderate(candidates[0], fifth, 'remove')).rejects.toThrow('Forbidden');
    await moderate(moderator, fifth, 'remove');
    expect(await anonymousListing('RR-0001')).toEqual(hidden);
    await expect(moderate(moderator, fifth, 'approve')).rejects.toThrow('Invalid transition');
  });

  it('serializes concurrent duplicate submissions and rejects invalid scores', async () => {
    await expect(submit(candidates[0], recruiter, score(0))).rejects.toThrow('Invalid rating');
    const results = await Promise.allSettled([submit(candidates[0], recruiter, score(2)), submit(candidates[0], recruiter, score(4))]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect(results.filter((r) => r.status === 'rejected')).toHaveLength(1);
  });

  it.each(['edit', 'remove'] as const)('does not revive an older approved duplicate after %s', async (action) => {
    for (const candidate of candidates) {
      const id = await submit(candidate, recruiter, score(3));
      await moderate(moderator, id, 'approve');
    }
    // Simulate a historical duplicate; only moderation changes its status.
    const interaction = await pool.query(`INSERT INTO interactions (recruiter_id, target_id, created_at, updated_at)
      VALUES ($1, $2, now(), now()) RETURNING id`, [recruiter, candidates[0].userId]);
    const experience = await pool.query(`INSERT INTO experiences (interaction_id, rating, status, created_at, updated_at)
      VALUES ($1, 5, 'pending', now(), now()) RETURNING id`, [interaction.rows[0].id]);
    const current = Number(experience.rows[0].id);
    await moderate(moderator, current, 'approve');
    expect(await anonymousListing('RR-0001')).toMatchObject({ count: 5, average: 3.4 });

    if (action === 'edit') await edit(candidates[0], current, score(4));
    else await moderate(moderator, current, 'remove');
    expect(await anonymousListing('RR-0001')).toEqual({ slug: 'RR-0001', displayName: 'Synthetic Name' });
    if (action === 'edit') {
      await moderate(moderator, current, 'approve');
      expect(await anonymousListing('RR-0001')).toMatchObject({ count: 5, average: 3.2 });
    }
  });

  it('only publishes categories supplied by five distinct eligible contributors', async () => {
    const ids: number[] = [];
    for (let n = 0; n < 5; n++) {
      const dimensions: Record<string, number> = { responsiveness: n + 1 };
      if (n < 4) dimensions.clarity = n + 1;
      if (n === 0) dimensions.rare = 5;
      const id = await submit(candidates[n], recruiter, { rating: n + 1, dimensions });
      ids.push(id);
      await moderate(moderator, id, 'approve');
    }
    // A repeated legacy metric is not an extra contributor.
    await pool.query(`INSERT INTO review_metrics (experience_id, dimension, score, created_at, updated_at)
      VALUES ($1, 'clarity', 1, now(), now())`, [ids[0]]);
    expect(await anonymousListing('RR-0001')).toEqual({
      slug: 'RR-0001', displayName: 'Synthetic Name', count: 5, average: 3,
      dimensions: { responsiveness: 3 },
    });
    await edit(candidates[4], ids[4], { rating: 5, dimensions: { responsiveness: 5, clarity: 5 } });
    expect(await anonymousListing('RR-0001')).toEqual({ slug: 'RR-0001', displayName: 'Synthetic Name' });
    await moderate(moderator, ids[4], 'approve');
    expect(await anonymousListing('RR-0001')).toEqual({
      slug: 'RR-0001', displayName: 'Synthetic Name', count: 5, average: 3,
      dimensions: { responsiveness: 3, clarity: 3 },
    });
  });
});
