'use client';

import Link from 'next/link';
import { useEffect, useState, type FormEvent } from 'react';
import { aggregate, dimensions, parseReview, storageKey, transition, type Dimension, type Kind, type Review, type Scores } from './simulation';

const targets: Record<Kind, { name: string; path: string }> = {
  firm: { name: 'Demo Fictional Firm', path: '/firm/1' },
  recruiter: { name: 'Demo Fictional Recruiter', path: '/recruiter/demo-fictional-recruiter' },
};

function useSimulation(kind: Kind) {
  const [review, setReview] = useState<Review | null>(null);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState('');
  useEffect(() => {
    function read() {
      try { setReview(parseReview(localStorage.getItem(storageKey(kind)))); setError(''); }
      catch { setError('Browser storage is unavailable or contains invalid simulation data.'); }
      setReady(true);
    }
    read();
    const onStorage = (event: StorageEvent) => { if (!event.key || event.key === storageKey(kind)) read(); };
    window.addEventListener('storage', onStorage);
    window.addEventListener('pageshow', read);
    return () => { window.removeEventListener('storage', onStorage); window.removeEventListener('pageshow', read); };
  }, [kind]);
  function change(action: 'submit' | 'approve' | 'remove' | 'reset', input?: { rating: number; scores: Scores }) {
    try {
      if (action === 'reset') {
        localStorage.removeItem(storageKey(kind));
        setReview(null);
      } else {
        const current = parseReview(localStorage.getItem(storageKey(kind)));
        const next = transition(current, action, input);
        localStorage.setItem(storageKey(kind), JSON.stringify(next));
        setReview(next);
      }
      setError('');
    } catch { setError('This action could not be saved. Check browser storage or reset this target.'); }
  }
  return { review, ready, error, change };
}

function Demo({ kind }: { kind: Kind }) {
  const { review, ready, error, change } = useSimulation(kind);
  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const scores: Scores = {};
    for (const key of Object.keys(dimensions) as Dimension[]) {
      const value = data.get(key);
      if (typeof value === 'string' && /^[1-5]$/.test(value)) scores[key] = Number(value);
    }
    change('submit', { rating: Number(data.get('rating')), scores });
  }
  return <main className="profile demo">
    <div className="eyebrow muted">SIMULATED WORKSPACE · BROWSER-LOCAL</div>
    <h1>Structured feedback walkthrough</h1>
    <p>Everything here is fictional. State belongs to this browser profile on this preview origin; tabs share it and may overwrite each other. It is editable, not real sign-in, shared public data or backend moderation. Do not enter personal information.</p>
    <nav><Link href="/demo?kind=firm">Fictional firm</Link> · <Link href="/demo?kind=recruiter">Fictional recruiter</Link> · <Link href={targets[kind].path}>View simulated public profile →</Link></nav>
    <p>Target: <strong>{targets[kind].name}</strong>. Four distinct fictional contributions are already approved.</p>
    {!ready ? <p className="js-loading">Loading this browser’s simulation…</p> : <>
      {error && <p role="alert">{error}</p>}
      <section className="summary"><h2>1. Simulated contributor</h2><p>Choose an overall score and at least one dimension; the rest may be N/A.</p>
        {!review && !error ? <form onSubmit={submit}>
          <label>Overall score <select name="rating" required defaultValue=""><option value="" disabled>Choose 1–5</option>{[1,2,3,4,5].map(n => <option key={n}>{n}</option>)}</select></label>
          {Object.entries(dimensions).map(([key, label]) => <label key={key}>{label}<select name={key} defaultValue="na"><option value="na">N/A</option>{[1,2,3,4,5].map(n => <option key={n}>{n}</option>)}</select></label>)}
          <button type="submit">Submit fictional feedback</button>
        </form> : review && <p>Fifth contribution: <strong>{review.status}</strong>.</p>}
      </section>
      <section className="summary"><h2>2. Simulated moderator</h2><p>Pending or removed contributions do not count. Approving the fifth reveals this browser’s simulated aggregate.</p>
        <p>Current state: <strong>{review?.status ?? 'not submitted'}</strong></p>
        {review && <div className="moderator-review"><h3>Fictional contribution to review</h3><dl><div><dt>Overall score</dt><dd>{review.rating} / 5</dd></div>{Object.entries(dimensions).map(([key, label]) => <div key={key}><dt>{label}</dt><dd>{review.scores[key as Dimension] ?? 'N/A'}</dd></div>)}</dl></div>}
        {!error && review?.status === 'pending' && <button onClick={() => change('approve')}>Approve fictional feedback</button>}
        {!error && (review?.status === 'pending' || review?.status === 'approved') && <button onClick={() => change('remove')}>Remove fictional feedback</button>}
        <button onClick={() => change('reset')}>Reset this target</button>
      </section>
    </>}
  </main>;
}

function Profile({ kind }: { kind: Kind }) {
  const { review, ready, error } = useSimulation(kind);
  const result = aggregate(review);
  return <main className="profile"><Link className="back" href="/">← Back to directory</Link><section className="profile-head"><div className={`avatar large ${kind}`}>{kind === 'firm' ? '✦' : 'DR'}</div><div><div className="eyebrow muted">SIMULATED {kind.toUpperCase()} PROFILE</div><h1>{targets[kind].name}</h1><p>Fictional listing · This browser’s local view</p></div></section>
    <div className="profile-grid"><section className="summary"><div className="eyebrow muted">CANDIDATE EXPERIENCE</div><h2>At a glance</h2>
      {!ready ? <p className="js-loading">Loading this browser’s simulation…</p> : error ? <p role="alert">{error}</p> : !result ? <div className="not-enough"><h3>Getting the full picture</h3><p>Aggregate feedback appears when five fictional contributors are approved.</p></div> : <><div className="overall"><strong>{result.average.toFixed(1)}</strong><div><span>OVERALL SCORE</span><p>out of 5 · {result.count} fictional approved contributions</p></div></div><div className="divider"/><h3>By category</h3><dl className="dimensions">{Object.entries(result.dimensions).map(([key, value]) => <div key={key}><dt>{dimensions[key as Dimension]}</dt><dd>{value.toFixed(1)} / 5</dd></div>)}</dl><p>Categories without five scores remain hidden.</p></>}
    </section><aside className="aside"><h3>A simulated local view</h3><p>Only approved fictional contributors count; every category has its own threshold. Other browsers do not share this state.</p><Link href={`/demo?kind=${kind}`}>Try the walkthrough →</Link></aside></div></main>;
}

export default function Walkthrough({ path, kind }: { path: string; kind: Kind }) {
  if (path === 'demo') return <Demo key={kind} kind={kind} />;
  if (path === 'firm/1') return <Profile kind="firm" />;
  if (path === 'recruiter/demo-fictional-recruiter') return <Profile kind="recruiter" />;
  if (path === 'methodology') return <main className="profile"><h1>Methodology</h1><p>This fictional simulation illustrates an overall threshold of five approved contributors and a separate threshold of five scores per category. It does not establish privacy or backend guarantees.</p><Link href="/demo">Try the walkthrough →</Link></main>;
  return <main><section className="intro"><div className="eyebrow"><span className="dot"/> CANDIDATE-FIRST RECRUITING</div><h1>Recruiter<br/><em>Rankings.</em></h1><p>Discover which partners prioritize candidate experience over quotas. Explore fictional quality signals focused on communication, transparency and professional ethics.</p><div className="intro-foot"><Link href="/demo">TRY THE SIMULATED FEEDBACK WORKSPACE →</Link></div></section><section className="directory"><div className="section-head"><div><div className="eyebrow muted">PUBLIC DIRECTORY · DEMO</div><h2>Find a recruiter or firm</h2><p>Explore fictional profiles and simulated aggregate feedback.</p></div></div><div className="cards">{(Object.keys(targets) as Kind[]).map(key => <Link className="card" href={targets[key].path} key={key}><div className={`avatar ${key}`}>{key === 'firm' ? '✦' : 'DR'}</div><div><h3>{targets[key].name}</h3><p>Fictional {key}</p></div><div className="card-bottom">View profile →</div></Link>)}</div></section><section className="privacy"><div><strong>Privacy is built into the picture.</strong><p>This preview simulates thresholds locally; it is not a backend or privacy guarantee. <Link href="/methodology">Read the methodology →</Link></p></div></section></main>;
}
