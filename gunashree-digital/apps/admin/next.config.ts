import type { NextConfig } from 'next';
const nextConfig: NextConfig = {
  async rewrites() {
    const api = process.env.API_SERVER_URL || 'http://localhost:4000';
    return [
      { source: '/api/:path*', destination: `${api}/api/:path*` },
      { source: '/uploads/:path*', destination: `${api}/uploads/:path*` },
    ];
  },
};
export default nextConfig;
