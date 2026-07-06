import { query } from '@/lib/db';

export interface ReviewMetric {
  metric_name: string;
  value: number;
}

export interface Review {
  id: number;
  recruiter_id: number;
  user_id: string | null;
  content: string;
  status: string;
  created_at: string;
  metrics: ReviewMetric[];
}

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

export async function getRecruiterReviews(recruiterId: number): Promise<Review[]> {
  const sql = `
    SELECT rv.*, rm.metric_name, rm.value 
    FROM reviews rv
    LEFT JOIN review_metrics rm ON rv.id = rm.review_id
    WHERE rv.recruiter_id = $1
    ORDER BY rv.created_at DESC
  `;
  const result = await query(sql, [recruiterId]);
  
  const reviewsMap = new Map<number, Review>();
  for (const row of result.rows) {
    if (!reviewsMap.has(row.id)) {
      reviewsMap.set(row.id, {
        id: row.id,
        recruiter_id: row.recruiter_id,
        user_id: row.user_id,
        content: row.content,
        status: row.status,
        created_at: row.created_at,
        metrics: []
      });
    }
    if (row.metric_name) {
      reviewsMap.get(row.id)!.metrics.push({
        metric_name: row.metric_name,
        value: row.value
      });
    }
  }
  return Array.from(reviewsMap.values());
}
