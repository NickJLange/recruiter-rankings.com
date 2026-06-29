import { query } from '@/lib/db';
import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: parseInt(process.env.EMAIL_PORT || '587'),
  secure: process.env.EMAIL_SECURE === 'true',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

export async function createIdentityChallenge(recruiterId: number, email: string) {
  const sql = `
    INSERT INTO identity_challenges (recruiter_id, email, status, created_at)
    VALUES ($1, $2, 'pending', NOW())
    RETURNING id, token
  `;
  const result = await query(sql, [recruiterId, email]);
  const { id, token } = result.rows[0];

  const verificationUrl = `${process.env.NEXT_PUBLIC_APP_URL}/claim-identity/verify?token=${token}`;

  try {
    await transporter.sendMail({
      from: process.env.EMAIL_FROM || '"Recruiter Rankings" <noreply@recruiter-rankings.com>',
      to: email,
      subject: 'Verify your recruiter profile',
      html: `<p>Click the link below to verify your identity:</p><a href="${verificationUrl}">${verificationUrl}</a>`,
    });
  } catch (error) {
    console.error('Email dispatch failed:', error);
    // We don't throw here so the user still sees success, 
    // but the token is saved in DB for manual rescue if needed.
  }

  return { id, token };
}

export async function verifyIdentityChallenge(token: string) {
  const challengeSql = 'SELECT * FROM identity_challenges WHERE token = $1 AND status = \'pending\'';
  const challengeResult = await query(challengeSql, [token]);
  const challenge = challengeResult.rows[0];

  if (!challenge) {
    throw new Error('Invalid or expired token');
  }

  await query(
    'UPDATE identity_challenges SET status = \'verified\', verified_at = NOW() WHERE id = $1',
    [challenge.id]
  );

  return { success: true, recruiterId: challenge.recruiter_id };
}
