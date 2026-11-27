import type { PoolClient } from 'pg';
import pool from '../src/lib/db';

// Identity is a synthetic test seam, not an authentication mechanism.
export type Actor = { userId: number; role: 'candidate' | 'moderator' };
export type Rating = { rating: number; dimensions: Record<string, number> };
type Target = { kind: 'recruiter' | 'firm'; id: number };
export const SUBMISSION_LIMIT = 10;

function validate(input: Rating) {
  const entries = Object.entries(input.dimensions);
  if (!entries.length || ![input.rating, ...entries.map(([, v]) => v)].every(v => Number.isInteger(v) && v >= 1 && v <= 5) ||
      entries.some(([name]) => !/^[a-z_]+$/.test(name))) throw new Error('Invalid rating');
}
async function transaction<T>(fn: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally { client.release(); }
}
async function metrics(client: PoolClient, id: number, values: Record<string, number>) {
  for (const [dimension, value] of Object.entries(values))
    await client.query('INSERT INTO rr8_metrics (review_id, dimension, score) VALUES ($1, $2, $3)', [id, dimension, value]);
}

export async function submit(actor: Actor, recruiterId: number, input: Rating): Promise<number> {
  return submitTarget(actor, { kind: 'recruiter', id: recruiterId }, input);
}
export async function submitFirm(actor: Actor, companyId: number, input: Rating): Promise<number> {
  return submitTarget(actor, { kind: 'firm', id: companyId }, input);
}
async function submitTarget(actor: Actor, target: Target, input: Rating): Promise<number> {
  validate(input);
  if (actor.role !== 'candidate') throw new Error('Forbidden');
  return transaction(async client => {
    const user = await client.query('SELECT id FROM users WHERE id = $1 FOR UPDATE', [actor.userId]);
    if (!user.rowCount) throw new Error('Not found');
    const rate = await client.query(`SELECT count(*)::int AS count FROM rr8_submissions
      WHERE contributor_id = $1 AND submitted_at > clock_timestamp() - interval '24 hours'`, [actor.userId]);
    if (rate.rows[0].count >= SUBMISSION_LIMIT) throw new Error('Submission limit');
    const slot = await client.query(`INSERT INTO rr8_slots (recruiter_id, company_id, contributor_id) VALUES ($1, $2, $3)
      ON CONFLICT DO NOTHING RETURNING id`, [target.kind === 'recruiter' ? target.id : null, target.kind === 'firm' ? target.id : null, actor.userId]);
    if (!slot.rowCount) throw new Error('Duplicate');
    const review = await client.query("INSERT INTO rr8_reviews (slot_id, rating, status) VALUES ($1, $2, 'pending') RETURNING id", [slot.rows[0].id, input.rating]);
    const id = Number(review.rows[0].id);
    await metrics(client, id, input.dimensions);
    await client.query('UPDATE rr8_slots SET current_review_id = $1 WHERE id = $2', [id, slot.rows[0].id]);
    await client.query('INSERT INTO rr8_submissions (contributor_id) VALUES ($1)', [actor.userId]);
    return id;
  });
}

async function lockCurrent(client: PoolClient, id: number) {
  const slot = await client.query(`SELECT s.id, s.contributor_id
    FROM rr8_slots s WHERE s.current_review_id = $1 FOR UPDATE OF s`, [id]);
  if (!slot.rowCount) return null;
  const review = await client.query('SELECT status FROM rr8_reviews WHERE id = $1 AND slot_id = $2', [id, slot.rows[0].id]);
  return review.rowCount ? { ...slot.rows[0], status: review.rows[0].status } : null;
}
export async function edit(actor: Actor, id: number, input: Rating): Promise<void> {
  validate(input);
  if (actor.role !== 'candidate') throw new Error('Forbidden');
  await transaction(async client => {
    const current = await lockCurrent(client, id);
    if (!current || Number(current.contributor_id) !== actor.userId || current.status === 'removed') throw new Error('Not found or forbidden');
    const updated = await client.query("UPDATE rr8_reviews SET rating = $1, status = 'pending' WHERE id = $2 AND status IN ('pending', 'approved') RETURNING id", [input.rating, id]);
    if (!updated.rowCount) throw new Error('Not found or forbidden');
    await client.query('DELETE FROM rr8_metrics WHERE review_id = $1', [id]);
    await metrics(client, id, input.dimensions);
  });
}
export async function moderate(actor: Actor, id: number, action: 'approve' | 'remove'): Promise<void> {
  if (actor.role !== 'moderator') throw new Error('Forbidden');
  if (action !== 'approve' && action !== 'remove') throw new Error('Invalid action');
  await transaction(async client => {
    const current = await lockCurrent(client, id);
    if (!current || (action === 'approve' ? current.status !== 'pending' : !['pending', 'approved'].includes(current.status))) throw new Error('Invalid transition or not found');
    const updated = await client.query('UPDATE rr8_reviews SET status = $1 WHERE id = $2 AND status = ANY($3::text[]) RETURNING id',
      [action === 'approve' ? 'approved' : 'removed', id, action === 'approve' ? ['pending'] : ['pending', 'approved']]);
    if (!updated.rowCount) throw new Error('Invalid transition or not found');
    await client.query('INSERT INTO rr8_moderation_decisions (review_id, moderator_id, decision) VALUES ($1, $2, $3)',
      [id, actor.userId, action]);
  });
}
export async function permanentlyDelete(actor: Actor, id: number): Promise<void> {
  if (actor.role !== 'moderator') throw new Error('Forbidden');
  await transaction(async client => {
    const current = await lockCurrent(client, id);
    if (!current) return;
    await client.query('DELETE FROM rr8_reviews WHERE id = $1', [id]);
  });
}
export async function anonymousListing(slug: string) {
  return listing('recruiter', slug);
}

export async function anonymousFirmListing(companyId: number) {
  return listing('firm', companyId);
}

async function listing(kind: Target['kind'], identifier: string | number) {
  const result = await pool.query(`WITH target AS (
    SELECT id, name, public_slug FROM recruiters WHERE $1 = 'recruiter' AND public_slug = $2::text
    UNION ALL
    SELECT id, name, NULL::varchar AS public_slug FROM companies WHERE $1 = 'firm' AND id::text = $2::text
  ), eligible AS (
    SELECT r.id, r.rating FROM rr8_slots s JOIN target t
      ON (($1 = 'recruiter' AND s.recruiter_id = t.id) OR ($1 = 'firm' AND s.company_id = t.id))
    JOIN rr8_reviews r ON r.id = s.current_review_id AND r.slot_id = s.id
    WHERE r.status = 'approved'
  ), overall AS (SELECT COUNT(*)::int count, AVG(rating)::float average FROM eligible),
  dimensions AS (SELECT m.dimension, AVG(m.score)::float average FROM rr8_metrics m
    JOIN eligible e ON e.id = m.review_id GROUP BY m.dimension HAVING COUNT(*) >= 5)
  SELECT t.id, t.name, t.public_slug, o.count, o.average,
    COALESCE((SELECT json_object_agg(dimension, average) FROM dimensions), '{}'::json) dimensions
  FROM target t CROSS JOIN overall o`, [kind, identifier]);
  const row = result.rows[0];
  if (!row) return null;
  const identity = kind === 'recruiter' ? { slug: row.public_slug, displayName: row.name } : { id: Number(row.id), displayName: row.name };
  return row.count >= 5 ? { ...identity, count: row.count, average: row.average, dimensions: row.dimensions } : identity;
}
