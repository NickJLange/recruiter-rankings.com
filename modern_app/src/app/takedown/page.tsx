import Link from 'next/link';
import { handleTakedownRequest } from './actions';

export default function TakedownPage() {
  return (
    <div className="p-8 max-w-2xl mx-auto min-h-screen">
      <nav className="mb-8">
        <Link href="/" className="text-sm text-blue-600 hover:underline">← Back to Home</Link>
      </nav>

      <div className="mb-10">
        <h1 className="text-4xl font-bold tracking-tight mb-2">Request Content Removal</h1>
        <p className="text-zinc-500">If you believe content on this site is inaccurate, defamatory, or violates your privacy, please submit a request below.</p>
      </div>

      <form 
        action={handleTakedownRequest} 
        className="space-y-6 bg-white p-8 border rounded-3xl shadow-sm border-zinc-200"
      >
        <div className="grid grid-cols-1 gap-6">
          <div className="space-y-2">
            <label className="block text-sm font-semibold text-zinc-700">Subject Type</label>
            <select 
              name="subject_type" 
              className="w-full p-4 border rounded-2xl bg-zinc-50 border-zinc-200 focus:ring-2 focus:ring-blue-500 outline-none"
            >
              <option value="Review">A Specific Review</option>
              <option value="Recruiter">A Recruiter Profile</option>
            </select>
          </div>

          <div className="space-y-2">
            <label className="block text-sm font-semibold text-zinc-700">Subject ID</label>
            <input 
              name="subject_id" 
              type="number" 
              required 
              placeholder="Enter the ID of the content"
              className="w-full p-4 border rounded-2xl bg-zinc-50 border-zinc-200 focus:ring-2 focus:ring-blue-500 outline-none" 
            />
          </div>

          <div className="space-y-2">
            <label className="block text-sm font-semibold text-zinc-700">Your Email</label>
            <input 
              name="requester_email" 
              type="email" 
              required 
              placeholder="email@example.com"
              className="w-full p-4 border rounded-2xl bg-zinc-50 border-zinc-200 focus:ring-2 focus:ring-blue-500 outline-none" 
            />
          </div>

          <div className="space-y-2">
            <label className="block text-sm font-semibold text-zinc-700">Reason for Request</label>
            <textarea 
              name="reason" 
              required 
              rows={5} 
              placeholder="Please provide a detailed explanation for the removal request..."
              className="w-full p-4 border rounded-2xl bg-zinc-50 border-zinc-200 focus:ring-2 focus:ring-blue-500 outline-none" 
            />
          </div>
        </div>

        <button 
          type="submit" 
          className="w-full py-4 bg-zinc-900 text-white font-bold rounded-2xl hover:bg-zinc-800 transition-all shadow-lg active:scale-95"
        >
          Submit Takedown Request
        </button>
      </form>
    </div>
  );
}
