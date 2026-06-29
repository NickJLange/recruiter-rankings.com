import Link from "next/link";

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen items-center justify-center bg-[#fcfcfc] font-sans dark:bg-zinc-950 px-4">
      <main className="flex flex-col items-center text-center max-w-4xl">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 text-blue-600 text-xs font-semibold mb-8 border border-blue-100 animate-fade-in">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"></span>
          </span>
          Verified Candidate Experiences
        </div>
        
        <h1 className="text-6xl font-extrabold tracking-tight text-zinc-900 dark:text-white mb-6 leading-[1.1]">
          Recruiter <span className="text-blue-600">Rankings</span>
        </h1>
        
        <p className="text-xl text-zinc-600 dark:text-zinc-400 mb-12 max-w-2xl leading-relaxed">
          The first transparent, k-anonymized directory of recruitment agencies. 
          Discover which partners prioritize candidate experience over quotas.
        </p>
        
        <div className="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
          <Link 
            href="/search" 
            className="px-8 py-4 bg-blue-600 text-white rounded-xl font-semibold hover:bg-blue-700 transition-all shadow-lg shadow-blue-200 dark:shadow-none active:scale-95 text-center"
          >
            Find a Recruiter
          </Link>
          <Link 
            href="/reviews/new" 
            className="px-8 py-4 bg-white text-zinc-900 border border-zinc-200 rounded-xl font-semibold hover:bg-zinc-50 transition-all active:scale-95 dark:bg-zinc-900 dark:text-white dark:border-zinc-800 dark:hover:bg-zinc-800 text-center"
          >
            Share Experience
          </Link>
        </div>

        <div className="mt-20 grid grid-cols-1 md:grid-cols-3 gap-8 text-left w-full border-t border-zinc-100 pt-12 dark:border-zinc-800">
          <div className="space-y-2">
            <div className="text-blue-600 font-bold text-lg">K-Anonymity</div>
            <p className="text-sm text-zinc-500 dark:text-zinc-400">Reviews only become public once a threshold is met, preventing targeted identification.</p>
          </div>
          <div className="space-y-2">
            <div className="text-blue-600 font-bold text-lg">Identity Verified</div>
            <p className="text-sm text-zinc-500 dark:text-zinc-400">Recruiters can claim profiles through verified corporate email challenges.</p>
          </div>
          <div className="space-y-2">
            <div className="text-blue-600 font-bold text-lg">Candidate-First</div>
            <p className="text-sm text-zinc-500 dark:text-zinc-400">Focused on communication quality, transparency, and professional ethics.</p>
          </div>
        </div>
      </main>
    </div>
  );
}
