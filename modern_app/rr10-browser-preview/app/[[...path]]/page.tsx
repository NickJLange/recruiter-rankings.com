import { notFound } from 'next/navigation';
import Walkthrough from '../walkthrough';

export const dynamic = 'force-dynamic';

function allowed() {
  return process.env.RR10_BROWSER_PREVIEW === 'enabled';
}

export async function generateMetadata() {
  if (!allowed()) notFound();
  return { title: 'Recruiter Rankings · Synthetic Preview', robots: { index: false, follow: false } };
}

export default async function Page({ params, searchParams }: { params: Promise<{ path?: string[] }>; searchParams: Promise<{ kind?: string }> }) {
  if (!allowed()) notFound();
  const path = (await params).path?.join('/') ?? '';
  if (!['', 'demo', 'firm/1', 'recruiter/demo-fictional-recruiter', 'methodology'].includes(path)) notFound();
  const kind = (await searchParams).kind === 'recruiter' ? 'recruiter' : 'firm';
  return <Walkthrough path={path} kind={kind} />;
}
