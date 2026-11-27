import pool from '../src/lib/db';

// Synthetic caller identities are supplied by the experiment harness, not authenticated users.
export type Actor = { userId: number; role: 'candidate' | 'moderator' };
export type Rating = { rating: number; dimensions: Record<string, number> };

function validate(input: Rating) {
  const scores = [input.rating, ...Object.values(input.dimensions)];
  if (!scores.every((score) => Number.isInteger(score) && score >= 1 && score <= 5) ||
      Object.keys(input.dimensions).length === 0 || Object.keys(input.dimensions).some((key) => !/^[a-z_]+$/.test(key))) {
    throw new Error('Invalid rating');
  }
}

export async function submit(actor: Actor, recruiterId: number, input: Rating): Promise<number> {
  validate(input);
  if (actor.role !== 'candidate') throw new Error('Forbidden');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const recruiter = await client.query('SELECT id FROM recruiters WHERE id = $1 FOR UPDATE', [recruiterId]);
    if (!recruiter.rowCount) throw new Error('Not found');
    const existing = await client.query('SELECT id FROM interactions WHERE recruiter_id = $1 AND target_id = $2', [recruiterId, actor.userId]);
    if (existing.rowCount) throw new Error('Duplicate');
    const interaction = await client.query(
      'INSERT INTO interactions (recruiter_id, target_id, occurred_at, created_at, updated_at) VALUES ($1, $2, now(), now(), now()) RETURNING id',
      [recruiterId, actor.userId]
    );
    const experience = await client.query(
      "INSERT INTO experiences (interaction_id, rating, status, created_at, updated_at) VALUES ($1, $2, 'pending', now(), now()) RETURNING id",
      [interaction.rows[0].id, input.rating]
    );
    await writeDimensions(client, experience.rows[0].id, input.dimensions);
    await client.query('COMMIT');
    return Number(experience.rows[0].id);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function writeDimensions(client: import('pg').PoolClient, id: number, dimensions: Record<string, number>) {
  for (const [dimension, score] of Object.entries(dimensions)) {
    await client.query('INSERT INTO review_metrics (experience_id, dimension, score, created_at, updated_at) VALUES ($1, $2, $3, now(), now())', [id, dimension, score]);
  }
}

export async function edit(actor: Actor, id: number, input: Rating): Promise<void> {
  validate(input);
  if (actor.role !== 'candidate') throw new Error('Forbidden');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query(
      "UPDATE experiences e SET rating = $1, status = 'pending', updated_at = now() FROM interactions i WHERE e.id = $2 AND e.interaction_id = i.id AND i.target_id = $3 AND e.status <> 'removed' RETURNING e.id",
      [input.rating, id, actor.userId]
    );
    if (!result.rowCount) throw new Error('Not found or forbidden');
    await client.query('DELETE FROM review_metrics WHERE experience_id = $1', [id]);
    await writeDimensions(client, id, input.dimensions);
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function moderate(actor: Actor, id: number, action: 'approve' | 'remove'): Promise<void> {
  if (actor.role !== 'moderator') throw new Error('Forbidden');
  if (action !== 'approve' && action !== 'remove') throw new Error('Invalid action');
  const result = await pool.query(
    "UPDATE experiences SET status = $1, updated_at = now() WHERE id = $2 AND status = ANY($3::text[]) RETURNING id",
    [action === 'approve' ? 'approved' : 'removed', id, action === 'approve' ? ['pending'] : ['pending', 'approved']]
  );
  if (!result.rowCount) throw new Error('Invalid transition or not found');
}

export async function anonymousListing(slug: string) {
  const result = await pool.query(`
    WITH current_records AS (
      SELECT DISTINCT ON (i.target_id) e.id, e.rating, e.status
      FROM experiences e JOIN interactions i ON i.id = e.interaction_id
      JOIN recruiters r ON r.id = i.recruiter_id
      WHERE r.public_slug = $1
      ORDER BY i.target_id, e.id DESC
    ), selected AS (
      SELECT id, rating FROM current_records WHERE status = 'approved'
    ), aggregate AS (
      SELECT COUNT(*)::int AS count, AVG(rating)::float AS average FROM selected
    ), selected_metrics AS (
      SELECT DISTINCT ON (s.id, m.dimension) s.id, m.dimension, m.score
      FROM review_metrics m JOIN selected s ON s.id = m.experience_id
      ORDER BY s.id, m.dimension, m.id DESC
    ), dimensions AS (
      SELECT dimension, AVG(score)::float AS average
      FROM selected_metrics
      GROUP BY dimension
      HAVING COUNT(*) >= 5
    )
    SELECT r.public_slug, r.name, a.count, a.average,
      COALESCE((SELECT json_object_agg(dimension, average) FROM dimensions), '{}'::json) AS dimensions
    FROM recruiters r CROSS JOIN aggregate a WHERE r.public_slug = $1`, [slug]);
  const row = result.rows[0];
  if (!row) return null;
  const listing = { slug: row.public_slug, displayName: row.name };
  return row.count >= 5 ? { ...listing, count: row.count, average: row.average, dimensions: row.dimensions } : listing;
}
