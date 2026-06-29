import { query } from '@/lib/db';

export async function submitReview(formData: FormData) {
  const recruiterId = formData.get('recruiter_id');
  const content = formData.get('content');
  const userId = formData.get('user_id'); // In real use, from Clerk auth

  if (!recruiterId || !content) {
    throw new Error('Missing required fields');
  }

  // 1. Check K-Anonymity (Mirroring Rails clean-room Logic)
  // Ensure the recruiter has enough reviews to avoid identification
  const countResult = await query(
    'SELECT count(*) FROM reviews WHERE recruiter_id = $1', 
    [recruiterId]
  );
  const reviewCount = parseInt(countResult.rows[0].count);

  if (reviewCount < 3) {
    // In a real scenario, we might queue this or warn the user
    // For now, we follow the clean-room logic of requiring a threshold
    return { success: false, error: 'Review submitted but hidden until k-anonymity threshold is met.' };
  }

  // 2. Insert Review
  const insertReview = await query(
    'INSERT INTO reviews (recruiter_id, user_id, content, status, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING id',
    [recruiterId, userId, content, 'pending']
  );

  return { success: true, id: insertReview.rows[0].id };
}
