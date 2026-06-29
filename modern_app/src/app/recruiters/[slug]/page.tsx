import { getRecruiterBySlug, getRecruiterReviews } from '@/lib/profiles';
import { notFound } from 'next/navigation';

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
      <div className="mb-8">
        <h1 className="text-3xl font-bold">{recruiter.pseudonym}</h1>
        <p className="text-gray-600">{recruiter.company_name}</p>
      </div>

      <h2 className="text-xl font-semibold mb-4">Reviews</h2>
      <div className="space-y-6">
        {reviews.length === 0 ? (
          <p className="text-gray-500">No reviews available for this recruiter.</p>
        ) : (
          reviews.map((review: any, idx: number) => (
            <div key={review.id} className="p-4 border rounded bg-white shadow-sm">
              <div className="text-sm text-gray-400 mb-2">
                {new Date(review.created_at).toLocaleDateString()}
              </div>
              <p className="text-gray-800 mb-4">{review.content}</p>
              <div className="flex flex-wrap gap-2">
                {/* Simple render of metrics associated with the review */}
                <span className="px-2 py-1 bg-gray-100 text-xs rounded">
                  Metric: {review.metric_name} | Value: {review.value}
                </span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
