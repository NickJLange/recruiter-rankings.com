/** @type {import('next').NextConfig} */
const config = {
  allowedDevOrigins: ['*.onamp.dev'],
  devIndicators: false,
  async headers() {
    return [{ source: '/:path*', headers: [
      { key: 'Cache-Control', value: 'no-store, max-age=0' },
      { key: 'X-Robots-Tag', value: 'noindex, nofollow' },
    ] }];
  },
};
export default config;
