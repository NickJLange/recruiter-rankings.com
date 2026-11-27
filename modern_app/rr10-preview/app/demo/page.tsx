import Link from 'next/link';
import { notFound } from 'next/navigation';
import { dimensions, enabled, state, type Kind } from './model';

export const dynamic = 'force-dynamic';
const options = [1, 2, 3, 4, 5];
export default async function Demo({ searchParams }: { searchParams: Promise<{ kind?: string }> }) {
  if (!await enabled()) notFound();
  const params = await searchParams;
  const kind: Kind = params.kind === 'recruiter' ? 'recruiter' : 'firm';
  const current = await state(kind);
  const profile = kind === 'firm' ? '/firm/1' : '/recruiter/demo-fictional-recruiter';
  return <main className="profile demo">
    <div className="eyebrow muted">SIMULATED WORKSPACE · SHARED STATE</div>
    <h1>Structured feedback walkthrough</h1>
    <p>All participants and feedback are fictional. Anyone with access can play both roles and reset this shared scenario. This is not authentication or production moderation.</p>
    <nav><Link href="/demo?kind=firm">Fictional firm</Link> · <Link href="/demo?kind=recruiter">Fictional recruiter</Link> · <Link href={profile}>View public profile →</Link></nav>
    <p>Target: <strong>{kind === 'firm' ? 'Demo Fictional Firm' : 'Demo Fictional Recruiter'}</strong>. Four fictional contributions are already approved.</p>
    <section className="summary">
      <h2>1. Simulated contributor</h2>
      <p>Choose an overall score and at least one dimension. The remaining dimensions may be N/A. No free text or personal information.</p>
      {!current ? <form method="post" action="/demo/action">
        <input type="hidden" name="kind" value={kind}/><input type="hidden" name="action" value="submit"/>
        <label>Overall score <select name="rating" required defaultValue=""><option value="" disabled>Choose 1–5</option>{options.map(n => <option key={n} value={n}>{n}</option>)}</select></label>
        {Object.entries(dimensions).map(([key, label]) => <label key={key}>{label}<select name={key} defaultValue="na"><option value="na">N/A</option>{options.map(n => <option key={n} value={n}>{n}</option>)}</select></label>)}
        <button type="submit">Submit fictional feedback</button>
      </form> : <p>Fifth contribution: <strong>{current.status}</strong>. Reset to submit again.</p>}
    </section>
    <section className="summary">
      <h2>2. Simulated moderator</h2>
      <p>The fifth submission is private while pending. Approving it makes the aggregate eligible; removing it suppresses the aggregate again.</p>
      <p>Current state: <strong>{current?.status ?? 'not submitted'}</strong></p>
      {current?.current_review_id && <div className="moderator-review">
        <h3>Fictional contribution to review</h3>
        <p>Visible only in this shared simulated workspace, not as individual feedback on public profiles.</p>
        <dl><div><dt>Overall score</dt><dd>{current.rating} / 5</dd></div>
          {Object.entries(dimensions).map(([key, label]) => <div key={key}><dt>{label}</dt><dd>{current.scores[key] === undefined ? 'N/A' : `${current.scores[key]} / 5`}</dd></div>)}
        </dl>
      </div>}
      {current?.status === 'pending' && <form method="post" action="/demo/action"><input type="hidden" name="kind" value={kind}/><button name="action" value="approve">Approve fictional feedback</button></form>}
      {(current?.status === 'pending' || current?.status === 'approved') && <form method="post" action="/demo/action"><input type="hidden" name="kind" value={kind}/><button name="action" value="remove">Remove fictional feedback</button></form>}
      <form method="post" action="/demo/action"><input type="hidden" name="kind" value={kind}/><button name="action" value="reset">Reset this target</button></form>
    </section>
  </main>;
}
