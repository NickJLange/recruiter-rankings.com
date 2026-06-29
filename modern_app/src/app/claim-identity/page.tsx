import { createIdentityChallenge } from '@/lib/identity';
import { redirect } from 'next/navigation';

export default async function ClaimIdentityPage() {
  return (
    <div className="p-8 max-w-md mx-auto">
      <h1 className="text-3xl font-bold tracking-tight mb-6">Claim Your Profile</h1>
      <form 
        action={async (formData) => {
          'use server';
          const recruiterId = Number(formData.get('recruiter_id'));
          const email = formData.get('email') as string;
          try {
            await createIdentityChallenge(recruiterId, email);
            redirect('/claim-identity/success');
          } catch (e) {
            console.error(e);
          }
        }} 
        className="space-y-6 bg-white p-6 border rounded-xl shadow-sm"
      >
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Recruiter ID</label>
            <input name="recruiter_id" type="number" required placeholder="e.g. 123" className="w-full p-3 border rounded-lg text-gray-900 focus:ring-2 focus:ring-blue-500 outline-none transition-all" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Verification Email</label>
            <input name="email" type="email" required placeholder="your@company.com" className="w-full p-3 border rounded-lg text-gray-900 focus:ring-2 focus:ring-blue-500 outline-none transition-all" />
          </div>
        </div>
        <button type="submit" className="w-full py-3 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors shadow-sm">
          Send Verification Email
        </button>
      </form>
    </div>
  );
}
