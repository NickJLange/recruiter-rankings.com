import { dimensions, enabled, mutate, type Kind } from '../model';

export async function POST(request: Request) {
  if (!await enabled()) return new Response('Not found', { status: 404 });
  const origin = process.env.RR10_PREVIEW_ORIGIN;
  if (!origin || request.headers.get('origin') !== origin || (request.headers.get('sec-fetch-site') && request.headers.get('sec-fetch-site') !== 'same-origin')) return new Response('Forbidden', { status: 403 });
  if (!request.headers.get('content-type')?.startsWith('application/x-www-form-urlencoded')) return new Response('Invalid request', { status: 400 });
  const body = await request.text();
  if (body.length > 2048) return new Response('Invalid request', { status: 400 });
  const form = new URLSearchParams(body);
  const allowed = new Set(['kind', 'action', 'rating', ...Object.keys(dimensions)]);
  if ([...form.keys()].some(key => !allowed.has(key) || form.getAll(key).length !== 1)) return new Response('Invalid request', { status: 400 });
  const kind = form.get('kind');
  const action = form.get('action');
  if ((kind !== 'firm' && kind !== 'recruiter') || !['submit', 'approve', 'remove', 'reset'].includes(action ?? '')) return new Response('Invalid request', { status: 400 });
  const rating = Number(form.get('rating'));
  const values: Record<string, number> = {};
  if (action === 'submit') {
    for (const key of Object.keys(dimensions)) {
      const value = form.get(key);
      if (value && value !== 'na') {
        if (!/^[1-5]$/.test(value)) return new Response('Invalid rating', { status: 400 });
        values[key] = Number(value);
      }
    }
    if (!/^[1-5]$/.test(form.get('rating') ?? '') || !Object.keys(values).length) return new Response('Choose an overall score and at least one dimension', { status: 400 });
  } else if ([...form.keys()].some(key => key !== 'kind' && key !== 'action')) return new Response('Invalid request', { status: 400 });
  try { await mutate(kind as Kind, action!, rating, values); }
  catch { return new Response('Transition denied or duplicate; reset the scenario if needed.', { status: 409 }); }
  return Response.redirect(`${origin}/demo?kind=${kind}`, 303);
}
