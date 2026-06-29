import { query } from '@/lib/db';

export async function createIdentityChallenge(recruiterId: number, email: string) {
  const sql = `
    INSERT INTO identity_challenges (recruiter_id, email, status, created_at)
    VALUES ($1, $2, 'pending', NOW())
    RETURNING id, token
  `;
  const result = await query(sql, [recruiterId, email]);
  return result.rows[0];
}

export async function verifyIdentityChallenge(token: string) {
  // 1. Find challenge
  const challengeSql = 'SELECT * FROM identity_challenges WHERE token = $1 AND status = \'pending\'';
  const challengeResult = await query(challengeSql, [token]);
  const challenge = challengeResult.rows[0];

  if (!challenge) {
    throw new Error('Invalid or expired token');
  }

  // 2. Mark as verified
  await query(
    'UPDATE identity_challenges SET status = \'verified\', verified_at = NOW() WHERE id = $1',
    [challenge.id]
  );

  // 3. Link to user (Assuming we have the user session)
  return { success: true, recruiterId: challenge.recruiter_id };
}
