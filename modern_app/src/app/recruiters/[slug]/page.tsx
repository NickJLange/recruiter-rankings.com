import { getRecruiterBySlug, getRecruiterReviews } from '@/lib/profiles';
import { notFound } from 'next/navigation';
import Link from 'next/link';

export default async function RecruiterProfile({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const recruiter = await getRecruiterBySlug(slug);

  if (!recruiter) {
    notFound();
  }

  const reviews = await getRecruiterReviews(recruiter.id);

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <nav className="mb-8">
        <Link href="/" className="text-sm text-blue-600 hover:underline">← Back to Home</Link>
      </nav>

      <div className="mb-12 pb-8 border-b">
        <div className="flex items-center gap-4 mb-2">
          <div className="w-16 h-16 bg-blue-100 text-blue-700 rounded-full flex items-center justify-center text-2xl font-bold">
            {recruiter.pseudonym[0]}
          </div>
          <div>
            <h1 className="text-4xl font-bold tracking-tight">{recruiter.pseudonym}</h1>
            <p className="text-lg text-gray-600">{recruiter.company_name}</p>
          </div>
        </div>
        <div className="mt-6 flex gap-3">
          {recruiter.is_verified && (
            <span className="px-2 py-1 bg-blue-50 text-blue-700 text-xs font-medium rounded-full border border-blue-200">
              ✓ Verified Identity
            </span>
          )}
          <span className="px-2 py-1 bg-gray-100 text-gray-600 text-xs font-medium rounded-full border border-gray-200">
            {reviews.length} reviews
          </span>
        </div>
      </div>

      <h2 className="text-2xl font-bold mb-6 tracking-tight">Candidate Experiences</h2>
      <div className="space-y-6">
        {reviews.length === 0 ? (
          <div className="text-center py-12 bg-gray-50 rounded-xl border-2 border-dashed border-gray-200">
            <p className="text-gray-500">No verified reviews available for this recruiter yet.</p>
          </div>
        ) : (
          reviews.map((review: any) => (
            <div key={review.id} className="p-6 border rounded-xl bg-white shadow-sm hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start mb-4">
                <div className="text-sm text-gray-400 font-medium">
                  {new Date(review.created_at).toLocaleDateString(undefined, { 
                    year: 'numeric', 
                    month: 'long', 
                    day: 'numeric' 
                  })}
                </div>
                {review.metric_name && (
                  <span className="px-3 py-1 bg-blue-50 text-blue-700 text-xs font-semibold rounded-full border border-blue-100">
                    {review.metric_name}: {review.value}
                  </span>
                )}
              </div>
              <p className="text-gray-800 leading-relaxed">{review.content}</p>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
