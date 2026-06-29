'use server';

import { createTakedownRequest } from '@/lib/takedowns';
import { redirect } from 'next/navigation';

export async function handleTakedownRequest(formData: FormData) {
  const subject_type = formData.get('subject_type') as 'Review' | 'Recruiter';
  const subject_id = parseInt(formData.get('subject_id') as string);
  const requester_email = formData.get('requester_email') as string;
  const reason = formData.get('reason') as string;

  if (!subject_type || isNaN(subject_id) || !requester_email || !reason) {
    throw new Error('Missing required fields');
  }

  await createTakedownRequest({
    subject_type,
    subject_id,
    requester_email,
    reason,
  });

  redirect('/takedown/success');
}
