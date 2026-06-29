import { query } from '@/lib/db';

export async function getRecruiterBySlug(slug: string) {
  const sql = `
    SELECT r.*, c.name as company_name 
    FROM recruiters r
    JOIN companies c ON r.company_id = c.id
    WHERE r.pseudonym = $1
    LIMIT 1
  `;
  const result = await query(sql, [slug]);
  return result.rows[0];
}

export async function getRecruiterReviews(recruiterId: number) {
  const sql = `
    SELECT rv.*, rm.metric_name, rm.value 
    FROM reviews rv
    JOIN review_metrics rm ON rv.id = rm.review_id
    WHERE rv.recruiter_id = $1
    ORDER BY rv.created_at DESC
  `;
  const result = await query(sql, [recruiterId]);
  return result.rows;
}
