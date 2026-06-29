import { query } from '@/lib/db';

export async function getRecruiters(searchQuery?: string) {
  if (!searchQuery) return [];

  // Simple search implementation based on pseudonym or company
  const sql = `
    SELECT r.id, r.pseudonym, c.name as company_name 
    FROM recruiters r
    JOIN companies c ON r.company_id = c.id
    WHERE r.pseudonym ILIKE $1 OR c.name ILIKE $1
    LIMIT 20
  `;
  
  const result = await query(sql, [`%${searchQuery}%`]);
  return result.rows;
}
