import Link from 'next/link';
import './style.css';
import './narrow.css';
import './story.css';
import './demo.css';

export default function Layout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>
    <div className="notice">SYNTHETIC PREVIEW <span>Browser-local simulation · No real sign-in or reviews</span></div>
    <header className="header"><Link href="/" className="brand"><span className="mark">R<span>R</span></span><span>recruiter<span className="brand-light">rankings</span></span></Link><span className="header-tag">CANDIDATE-FIRST RECRUITING</span></header>
    <noscript><style>{'.js-loading { display: none }'}</style><p className="profile">JavaScript is required for the browser-local fictional walkthrough. No feedback is submitted or saved without it.</p></noscript>
    {children}
    <footer><span>Recruiter Rankings · 5L Labs LLC</span><Link href="/methodology">Methodology</Link><span>Fictional browser-local preview</span></footer>
  </body></html>;
}
