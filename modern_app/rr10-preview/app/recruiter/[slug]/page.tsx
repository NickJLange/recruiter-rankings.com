import { notFound } from 'next/navigation';
import { anonymousListing } from '../../../../rr8/reviews';
import ProfileView from '../../profile';
import { canonical } from '../../origin';
export const dynamic = 'force-dynamic';
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  return { alternates: { canonical: canonical(`/recruiter/${encodeURIComponent(slug)}`) } };
}
export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const profile = await anonymousListing(slug);
  if (!profile) notFound();
  return <ProfileView profile={profile} kind="Recruiter" url={canonical(`/recruiter/${encodeURIComponent(slug)}`)} />;
}
