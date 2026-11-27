import Link from 'next/link';
import HistoryRefresh from './history-refresh';
import { enabled } from './demo/model';
import './style.css';
import './narrow.css';
import './story.css';
import './demo/demo.css';
export const metadata = { title: 'Recruiter Rankings · Synthetic Preview', robots: { index: false, follow: false } };
export default async function Layout({ children }: Readonly<{ children: React.ReactNode }>) {
  const demo = await enabled();
  return <html lang="en"><body><HistoryRefresh/><div className="notice">SYNTHETIC PREVIEW <span>{demo ? 'Fictional data · Shared simulated roles · No real sign-in' : 'Fictional data · Read-only · No sign-in or submissions'}</span></div><header className="header"><Link href="/" className="brand"><span className="mark">R<span>R</span></span><span>recruiter<span className="brand-light">rankings</span></span></Link><span className="header-tag">CANDIDATE-FIRST RECRUITING</span></header>{children}<footer><span>Recruiter Rankings <b>·</b> 5L Labs LLC</span><Link href="/methodology">Methodology</Link><span>Fictional preview · No real sign-in</span></footer></body></html>;
}
