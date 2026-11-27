'use client';

import { useEffect } from 'react';

// Next restores prior page payloads on history navigation even for dynamic pages.
// Hide the old page and reload rather than re-expose a withdrawn aggregate.
export default function HistoryRefresh() {
  useEffect(() => {
    const reload = () => {
      document.querySelector('main')?.setAttribute('hidden', '');
      window.location.reload();
    };
    const onPop = (event: PopStateEvent) => { event.stopImmediatePropagation(); reload(); };
    const onShow = (event: PageTransitionEvent) => { if (event.persisted) reload(); };
    window.addEventListener('popstate', onPop, true);
    window.addEventListener('pageshow', onShow);
    return () => { window.removeEventListener('popstate', onPop, true); window.removeEventListener('pageshow', onShow); };
  }, []);
  return null;
}
