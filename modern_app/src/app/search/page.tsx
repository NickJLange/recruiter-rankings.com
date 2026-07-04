import { getRecruiters } from '@/lib/recruiters';
import Link from 'next/link';

interface Recruiter {
  id: number;
  slug: string;
  pseudonym: string;
  company_name: string;
}

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q: query } = await searchParams;
  const recruiters = query ? await getRecruiters(query) as Recruiter[] : [];

  return (
    <div className="p-8 max-w-4xl mx-auto min-h-screen">
      <nav className="mb-8">
        <Link href="/" className="text-sm text-blue-600 hover:underline">← Back to Home</Link>
      </nav>

      <div className="mb-12">
        <h1 className="text-4xl font-bold tracking-tight mb-2">Find a Recruiter</h1>
        <p className="text-zinc-500">Search through verified candidate experiences.</p>
      </div>

      <form action="/search" method="GET" className="mb-12 flex gap-3">
        <div className="relative flex-1">
          <input
            name="q"
            defaultValue={query}
            placeholder="Search by name or company..."
            className="w-full p-4 pl-5 border rounded-2xl bg-white text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 outline-none transition-all border-zinc-200"
          />
        </div>
        <button type="submit" className="px-8 py-4 bg-blue-600 text-white font-semibold rounded-2xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-100 active:scale-95">
          Search
        </button>
      </form>

      <div className="space-y-4">
        {!query && (
          <div className="text-center py-20 bg-zinc-50 rounded-3xl border-2 border-dashed border-zinc-200">
            <p className="text-zinc-400">Enter a name or agency to begin searching.</p>
          </div>
        )}
        
        {query && recruiters.length === 0 && (
          <div className="text-center py-20 bg-zinc-50 rounded-3xl border-2 border-dashed border-zinc-200">
            <p className="text-zinc-500 mb-2">No results found for &ldquo;{query}&rdquo;.</p>
            <p className="text-sm text-zinc-400">Try different keywords or check the spelling.</p>
          </div>
        )}

        <div className="grid gap-4">
          {recruiters.map((r: Recruiter) => (
            <Link 
              key={r.id} 
              href={`/recruiters/${r.slug}`} 
              className="p-5 border rounded-2xl hover:border-blue-300 hover:bg-blue-50/30 transition-all group shadow-sm bg-white flex justify-between items-center"
            >
              <div>
                <div className="font-bold text-lg group-hover:text-blue-700 transition-colors">{r.pseudonym}</div>
                <div className="text-sm text-zinc-500">{r.company_name}</div>
              </div>
              <div className="text-blue-600 opacity-0 group-hover:opacity-100 transition-opacity font-medium text-sm">
                View Profile →
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}

