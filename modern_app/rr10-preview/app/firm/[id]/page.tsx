import { notFound } from 'next/navigation';
import { anonymousFirmListing } from '../../../../rr8/reviews';
import ProfileView from '../../profile';
import { canonical } from '../../origin';
export const dynamic = 'force-dynamic';
export async function generateMetadata({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return { alternates: { canonical: canonical(`/firm/${encodeURIComponent(id)}`) } };
}
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!/^[1-9]\d{0,14}$/.test(id) || !Number.isSafeInteger(Number(id))) notFound();
  const profile = await anonymousFirmListing(Number(id));
  if (!profile) notFound();
  return <ProfileView profile={profile} kind="Firm" url={canonical(`/firm/${id}`)} />;
}
