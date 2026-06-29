import { getRecruiters } from '@/lib/recruiters';

export default async function SearchPage({
  searchParams,
}: {
  searchParams: { q?: string };
}) {
  const query = searchParams.q;
  const recruiters = query ? await getRecruiters(query) : [];

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Search Recruiters</h1>
      <form action="/search" method="GET" className="mb-8 flex gap-2">
        <input
          name="q"
          defaultValue={query}
          placeholder="Search by pseudonym or company..."
          className="flex-1 p-2 border rounded text-black"
        />
        <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded">
          Search
        </button>
      </form>

      <div className="space-y-4">
        {!query && <p className="text-gray-500">Enter a search term to find recruiters.</p>}
        {query && recruiters.length === 0 && <p className="text-gray-500">No results found.</p>}
         {recruiters.map((r: any) => (
          <div key={r.id} className="p-4 border rounded hover:bg-gray-50 cursor-pointer">
            <div className="font-medium">{r.pseudonym}</div>
            <div className="text-sm text-gray-600">{r.company_name}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
