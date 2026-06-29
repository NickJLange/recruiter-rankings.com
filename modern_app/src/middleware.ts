import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const url = request.nextUrl;

  // Legacy SEO Redirects
  // Mapping /recruiters/:id -> /person/:id
  if (url.pathname.startsWith('/recruiters/')) {
    const id = url.pathname.split('/')[2];
    if (id) {
      return NextResponse.redirect(new URL(`/person/${id}`, request.url), 301);
    }
  }

  // Generic legacy recruiter list redirect
  if (url.pathname === '/recruiters') {
    return NextResponse.redirect(new URL('/search', request.url), 301);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    '/recruiters/:path*',
  ],
};
