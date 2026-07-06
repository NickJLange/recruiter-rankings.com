import { MetadataRoute } from 'next';
import { pool } from '@/lib/db';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  try {
    const result = await pool.query('SELECT id, updated_at FROM recruiters LIMIT 1000');
    const recruiterUrls = result.rows.map((row) => ({
      url: `https://recruiter-rankings.com/person/${row.id}`,
      lastModified: row.updated_at ? new Date(row.updated_at) : new Date(),
      changeFrequency: 'monthly' as const,
      priority: 0.7,
    }));

    return [
      {
        url: 'https://recruiter-rankings.com',
        lastModified: new Date(),
        changeFrequency: 'daily' as const,
        priority: 1,
      },
      {
        url: 'https://recruiter-rankings.com/search',
        lastModified: new Date(),
        changeFrequency: 'daily' as const,
        priority: 0.9,
      },
      {
        url: 'https://recruiter-rankings.com/takedown',
        lastModified: new Date(),
        changeFrequency: 'monthly' as const,
        priority: 0.3,
      },
      ...recruiterUrls,
    ];
  } catch (error) {
    console.error('Sitemap generation error:', error);
    return [{ url: 'https://recruiter-rankings.com', lastModified: new Date() }];
  }
}
