import { submitReview } from '@/lib/reviews';
import { redirect } from 'next/navigation';
import Link from 'next/link';

export default async function ReviewPage() {
  return (
    <div className="p-8 max-w-2xl mx-auto min-h-screen">
      <nav className="mb-8">
        <Link href="/" className="text-sm text-blue-600 hover:underline">← Back to Home</Link>
      </nav>

      <div className="mb-10">
        <h1 className="text-4xl font-bold tracking-tight mb-2">Share Your Experience</h1>
        <p className="text-zinc-500">Your insights help other candidates navigate the recruitment landscape.</p>
      </div>

      <form 
        action={async (formData) => {
          'use server';
          try {
            const result = await submitReview(formData);
            if (result.success) {
              redirect('/reviews/success');
            } else {
              console.log(result.error);
            }
          } catch (e) {
            console.error(e);
          }
        }} 
        className="space-y-8 bg-white p-8 border rounded-3xl shadow-sm border-zinc-200"
      >
        <div className="grid grid-cols-1 gap-6">
          <div className="space-y-2">
            <label className="block text-sm font-semibold text-zinc-700">Recruiter ID</label>
            <input 
              name="recruiter_id" 
              type="number" 
              required 
              placeholder="e.g. 12345"
              className="w-full p-4 border rounded-2xl text-gray-900 focus:ring-2 focus:ring-blue-500 outline-none transition-all border-zinc-200 bg-zinc-50 focus:bg-white" 
            />
            <p className="text-xs text-zinc-400 leading-relaxed">
              You can find the Recruiter ID on their profile page.
            </p>
          </div>
          
          <div className="space-y-2">
            <label className="block text-sm font-semibold text-zinc-700">Your Experience</label>
            <textarea 
              name="content" 
              required 
              rows={8} 
              placeholder="What was it like working with this recruiter? Mention communication, honesty, and professional conduct..."
              className="w-full p-4 border rounded-2xl text-gray-900 focus:ring-2 focus:ring-blue-500 outline-none transition-all border-zinc-200 bg-zinc-50 focus:bg-white" 
            />
          </div>
        </div>

        <div className="p-4 bg-blue-50 rounded-2xl border border-blue-100">
          <div className="flex gap-3">
            <span className="text-blue-600 font-bold">🛡️</span>
            <p className="text-xs text-blue-700 leading-relaxed">
              <strong>Privacy Notice:</strong> Your review is stored securely and will only become public once 3 or more candidates have reviewed this recruiter (k-anonymity).
            </p>
          </div>
        </div>

        <button 
          type="submit" 
          className="w-full py-4 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-100 active:scale-95"
        >
          Submit Verified Review
        </button>
      </form>
    </div>
  );
}
