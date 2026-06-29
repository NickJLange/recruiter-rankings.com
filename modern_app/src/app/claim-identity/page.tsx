import { createIdentityChallenge } from '@/lib/identity';
import { redirect } from 'next/navigation';

export default async function ClaimIdentityPage() {
  return (
    <div className="p-8 max-w-md mx-auto">
      <h1 className="text-2xl font-bold mb-6">Claim Your Profile</h1>
      <form 
        action={async (formData) => {
          'use server';
          const recruiterId = Number(formData.get('recruiter_id'));
          const email = formData.get('email') as string;
          try {
            await createIdentityChallenge(recruiterId, email);
            // In production, send email here
            redirect('/claim-identity/success');
          } catch (e) {
            console.error(e);
          }
        }} 
        className="space-y-4"
      >
        <div>
          <label className="block text-sm font-medium mb-1">Recruiter ID</label>
          <input name="recruiter_id" type="number" required className="w-full p-2 border rounded text-black" />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Verification Email</label>
          <input name="email" type="email" required className="w-full p-2 border rounded text-black" />
        </div>
        <button type="submit" className="w-full py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Send Verification Email
        </button>
      </form>
    </div>
  );
}
