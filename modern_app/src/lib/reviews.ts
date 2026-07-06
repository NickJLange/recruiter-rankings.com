import pool from '@/lib/db';

export async function submitReview(formData: FormData) {
  const recruiterId = formData.get('recruiter_id');
  const content = formData.get('content');
  const userId = formData.get('user_id'); // In real use, from Clerk auth

  if (!recruiterId || !content) {
    throw new Error('Missing required fields');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Insert Review as 'hidden' initially
    // This ensures the review is captured even before the threshold is met
    const insertReview = await client.query(
      'INSERT INTO reviews (recruiter_id, user_id, content, status, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING id',
      [recruiterId, userId, content, 'hidden']
    );
    const reviewId = insertReview.rows[0].id;

    // 2. Check K-Anonymity
    // Count reviews that are NOT hidden to see if we meet the threshold
    // or count total reviews including this one to see if it SHOULD be revealed
    const countResult = await client.query(
      'SELECT count(*) FROM reviews WHERE recruiter_id = $1', 
      [recruiterId]
    );
    const reviewCount = parseInt(countResult.rows[0].count);

    if (reviewCount >= 3) {
      // Threshold met: Reveal all reviews for this recruiter
      await client.query(
        'UPDATE reviews SET status = $1 WHERE recruiter_id = $2',
        ['pending', recruiterId]
      );
      await client.query('COMMIT');
      return { success: true, id: reviewId, revealed: true };
    }

    await client.query('COMMIT');
    return { 
      success: true, 
      id: reviewId, 
      revealed: false, 
      error: 'Review submitted. It will become visible once more reviews are submitted for this recruiter.' 
    };
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error submitting review in transaction:', error);
    return { success: false, error: 'Database transaction error occurred' };
  } finally {
    client.release();
  }
}
