import Link from 'next/link';

export default function ReviewSuccessPage() {
  return (
    <div className="p-8 max-w-2xl mx-auto min-h-screen flex flex-col justify-center items-center text-center">
      <div className="mb-6 text-6xl">🎉</div>
      <h1 className="text-4xl font-bold tracking-tight mb-4 text-zinc-900">Review Submitted Successfully!</h1>
      <p className="text-zinc-600 mb-8 max-w-md">
        Thank you for sharing your experience. To protect candidate privacy, reviews are stored securely and will become public once at least 3 candidates have reviewed this recruiter (k-anonymity).
      </p>
      <Link href="/" className="px-6 py-3 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-100">
        Back to Home
      </Link>
    </div>
  );
}
