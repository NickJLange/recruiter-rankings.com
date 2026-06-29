import { pool } from './db';

export type TakedownStatus = 'pending' | 'in_review' | 'resolved' | 'rejected';

export interface TakedownRequest {
  id: number;
  subject_type: 'Review' | 'Recruiter';
  subject_id: number;
  requester_email: string;
  reason: string;
  status: TakedownStatus;
  created_at: Date;
}

export async function createTakedownRequest(data: {
  subject_type: 'Review' | 'Recruiter';
  subject_id: number;
  requester_email: string;
  reason: string;
}) {
  const { subject_type, subject_id, requester_email, reason } = data;
  const result = await pool.query(
    'INSERT INTO takedown_requests (subject_type, subject_id, requester_email, reason) VALUES ($1, $2, $3, $4) RETURNING *',
    [subject_type, subject_id, requester_email, reason]
  );
  return result.rows[0];
}

export async function getTakedownRequests(status?: TakedownStatus) {
  const query = status 
    ? 'SELECT * FROM takedown_requests WHERE status = $1 ORDER BY created_at DESC'
    : 'SELECT * FROM takedown_requests ORDER BY created_at DESC';
  const params = status ? [status] : [];
  const result = await pool.query(query, params);
  return result.rows;
}

export async function updateTakedownStatus(id: number, status: TakedownStatus) {
  const result = await pool.query(
    'UPDATE takedown_requests SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
    [status, id]
  );
  return result.rows[0];
}
