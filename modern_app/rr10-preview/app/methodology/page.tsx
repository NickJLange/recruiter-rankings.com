import Link from 'next/link';
import { canonical } from '../origin';
import { enabled } from '../demo/model';

export const metadata = { title: 'Methodology · Synthetic Preview', alternates: { canonical: canonical('/methodology') } };

const dimensions = ['Responsiveness', 'Clarity and accuracy of role description', 'Understanding candidate needs', 'Fairness and inclusivity', 'Timeline management', 'Feedback quality', 'Professionalism and respect', 'Job–role match quality'];
export const dynamic = 'force-dynamic';
export default async function Methodology() {
  const demo = await enabled();
  return <main className="profile"><Link className="back" href="/">← &nbsp; Back to directory</Link><section className="summary methodology"><div className="eyebrow muted">CANDIDATE-FIRST · SYNTHETIC PREVIEW</div><h1>Methodology</h1><p>Recruiter Rankings aims to improve the recruiter–candidate experience through standardized quality signals and a safe right of reply. All firms, people and feedback in this preview are fictional.</p><h2>Quality dimensions</h2><p>Our intended framework considers eight aspects of candidate experience. The fictional demo data does not yet represent all eight.</p><ul>{dimensions.map(dimension => <li key={dimension}>{dimension}</li>)}</ul><h2>Privacy thresholds</h2><p>Overall scores appear only when at least five distinct contributors have approved feedback for that target. Each category independently requires at least five distinct approved contributors who supplied that category.</p><p>Removed or pending feedback does not contribute. Individual reviews and contributor identities are not published.</p><h2>What is planned</h2><p>Real candidate submissions, LinkedIn sign-in with Clerk, recruiter claims, safe replies and moderation are planned—not available or verified in this demo. {demo && 'The feedback workspace simulates roles using fictional shared data only.'} Future benchmarks should protect against disclosure of individual feedback.</p></section></main>;
}
