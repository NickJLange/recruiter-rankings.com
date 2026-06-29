import { submitReview } from '@/lib/reviews';
import { redirect } from 'next/navigation';

export default async function ReviewPage() {
  return (
    <div className="p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Submit a Review</h1>
      <form 
        action={async (formData) => {
          'use server';
          try {
            const result = await submitReview(formData);
            if (result.success) {
              redirect('/reviews/success');
            } else {
              // Handle k-anonymity warning
              console.log(result.error);
            }
          } catch (e) {
            console.error(e);
          }
        }} 
        className="space-y-4"
      >
        <div>
          <label className="block text-sm font-medium mb-1">Recruiter ID</label>
          <input 
            name="recruiter_id" 
            type="number" 
            required 
            className="w-full p-2 border rounded text-black" 
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Your Experience</label>
          <textarea 
            name="content" 
            required 
            rows={5} 
            className="w-full p-2 border rounded text-black" 
          />
        </div>
        <button 
          type="submit" 
          className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
        >
          Submit Review
        </button>
      </form>
    </div>
  );
}
