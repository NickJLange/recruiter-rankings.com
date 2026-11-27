import pool from '../../../src/lib/db';
import { moderate, submit, submitFirm } from '../../../rr8/reviews';

export const dimensions = {
  responsiveness: 'Responsiveness', role_clarity: 'Clarity and accuracy of role description', candidate_needs: 'Understanding candidate needs',
  fairness: 'Fairness and inclusivity', timeline: 'Timeline management', feedback_quality: 'Feedback quality',
  professionalism: 'Professionalism and respect', job_match: 'Job–role match quality',
} as const;
export type Kind = 'firm' | 'recruiter';

// The opt-in must point at the separately initialized local demo cluster.
export async function enabled() {
  if (process.env.RR10_SYNTHETIC_DEMO !== 'enabled' || !process.env.DATABASE_URL || !process.env.RR10_DEMO_DATA_DIR?.startsWith('/')) return false;
  let url: URL;
  try { url = new URL(process.env.DATABASE_URL); } catch { return false; }
  if (url.protocol !== 'postgres:' || url.hostname !== '127.0.0.1' || url.port !== '55439' || url.pathname !== '/rr10_moderation_demo' || url.search || url.hash) return false;
  try {
    const result = await pool.query("SELECT current_database() AS db, host(inet_server_addr()) AS host, current_setting('data_directory') AS directory, (SELECT marker FROM rr10_demo_marker LIMIT 1) AS marker");
    return result.rows[0]?.db === 'rr10_moderation_demo' && result.rows[0]?.host === '127.0.0.1' && result.rows[0]?.directory === process.env.RR10_DEMO_DATA_DIR && result.rows[0]?.marker === 'synthetic-only-rr10-v1';
  } catch { return false; }
}

export async function state(kind: Kind) {
  const result = await pool.query<{ current_review_id: string | null; status: string | null; rating: number | null; scores: Record<string, number> }>(`SELECT s.current_review_id, r.status, r.rating,
    COALESCE((SELECT json_object_agg(m.dimension, m.score) FROM rr8_metrics m WHERE m.review_id = r.id), '{}'::json) AS scores
    FROM rr8_slots s
    JOIN users u ON u.id=s.contributor_id LEFT JOIN rr8_reviews r ON r.id=s.current_review_id
    WHERE u.email_hmac='rr10-demo-contributor-5' AND ${kind === 'firm' ? 's.company_id' : 's.recruiter_id'}=1`);
  return result.rows[0] ?? null;
}

export async function mutate(kind: Kind, action: string, rating: number, values: Record<string, number>) {
  const lock = await pool.connect();
  let transaction = false;
  try {
    await lock.query('SELECT pg_advisory_lock(721010)');
    const ids = await pool.query("SELECT id, email_hmac FROM users WHERE email_hmac IN ('rr10-demo-contributor-5', 'rr10-demo-moderator')");
    const candidate = ids.rows.find(r => r.email_hmac === 'rr10-demo-contributor-5');
    const moderator = ids.rows.find(r => r.email_hmac === 'rr10-demo-moderator');
    if (!candidate || !moderator) throw new Error('Missing fixtures');
    const current = await state(kind);
    if (action === 'submit') {
      if (current) throw new Error('Duplicate');
      const input = { rating, dimensions: values };
      const actor = { userId: Number(candidate.id), role: 'candidate' as const };
      if (kind === 'firm') await submitFirm(actor, 1, input); else await submit(actor, 1, input);
    } else if (action === 'approve' || action === 'remove') {
      if (!current?.current_review_id) throw new Error('No review');
      await moderate({ userId: Number(moderator.id), role: 'moderator' }, Number(current.current_review_id), action);
    } else if (action === 'reset') {
      await lock.query('BEGIN');
      transaction = true;
      const slots = await lock.query(`SELECT id, current_review_id FROM rr8_slots WHERE contributor_id=$1 AND ${kind === 'firm' ? 'company_id' : 'recruiter_id'}=1`, [candidate.id]);
      for (const slot of slots.rows) {
        await lock.query('DELETE FROM rr8_moderation_decisions WHERE review_id=$1', [slot.current_review_id]);
        await lock.query('DELETE FROM rr8_reviews WHERE id=$1', [slot.current_review_id]);
        await lock.query('DELETE FROM rr8_slots WHERE id=$1', [slot.id]);
      }
      // These records belong only to the fixed synthetic contributor, shared by both scenarios.
      await lock.query('DELETE FROM rr8_submissions WHERE contributor_id=$1', [candidate.id]);
      await lock.query('COMMIT');
      transaction = false;
    } else throw new Error('Invalid action');
  } catch (error) {
    if (transaction) await lock.query('ROLLBACK');
    throw error;
  } finally {
    await lock.query('SELECT pg_advisory_unlock(721010)');
    lock.release();
  }
}
