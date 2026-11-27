export const dimensions = {
  responsiveness: 'Responsiveness', role_clarity: 'Clarity and accuracy of role description',
  candidate_needs: 'Understanding candidate needs', fairness: 'Fairness and inclusivity',
  timeline: 'Timeline management', feedback_quality: 'Feedback quality',
  professionalism: 'Professionalism and respect', job_match: 'Job–role match quality',
} as const;
export type Dimension = keyof typeof dimensions;
export type Kind = 'firm' | 'recruiter';
export type Scores = Partial<Record<Dimension, number>>;
export type Review = { status: 'pending' | 'approved' | 'removed'; rating: number; scores: Scores };
export const storageKey = (kind: Kind) => `rr10-browser-preview-v1:${kind}`;

function score(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value >= 1 && value <= 5;
}
export function parseReview(raw: string | null): Review | null {
  if (raw === null) return null;
  const value: unknown = JSON.parse(raw);
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid stored simulation');
  const item = value as Record<string, unknown>;
  if (!['pending', 'approved', 'removed'].includes(String(item.status)) || !score(item.rating) || !item.scores || typeof item.scores !== 'object' || Array.isArray(item.scores)) throw new Error('Invalid stored simulation');
  const entries = Object.entries(item.scores);
  if (!entries.length || entries.some(([key, value]) => !Object.hasOwn(dimensions, key) || !score(value))) throw new Error('Invalid stored simulation');
  return { status: item.status as Review['status'], rating: item.rating, scores: Object.fromEntries(entries) as Scores };
}

export function transition(current: Review | null, action: 'submit' | 'approve' | 'remove', input?: { rating: number; scores: Scores }): Review {
  if (action === 'submit') {
    if (current || !input) throw new Error('Duplicate or invalid submission');
    return parseReview(JSON.stringify({ ...input, status: 'pending' }))!;
  }
  if (!current || (action === 'approve' && current.status !== 'pending') || (action === 'remove' && !['pending', 'approved'].includes(current.status))) throw new Error('Invalid transition');
  return { ...current, status: action === 'approve' ? 'approved' : 'removed' };
}

export function aggregate(current: Review | null) {
  if (current?.status !== 'approved') return null;
  const averages: Scores = {};
  for (const key of Object.keys(dimensions) as Dimension[]) {
    const value = current.scores[key];
    if (value !== undefined) averages[key] = (16 + value) / 5;
  }
  return { count: 5, average: (16 + current.rating) / 5, dimensions: averages };
}
