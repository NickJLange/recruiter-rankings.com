import type { MetadataRoute } from 'next';
import pool from '../../src/lib/db';
import { canonical } from './origin';

export const dynamic = 'force-dynamic';
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const { rows } = await pool.query(`SELECT 'firm' kind, id::text key FROM companies UNION ALL SELECT 'recruiter' kind, public_slug key FROM recruiters WHERE public_slug IS NOT NULL`);
  return ['/', '/methodology', ...rows.map(row => `/${row.kind}/${encodeURIComponent(row.key)}`)].map(path => ({ url: canonical(path) }));
}
