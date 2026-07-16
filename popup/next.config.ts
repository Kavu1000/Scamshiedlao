/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export",          // Static export — required for Chrome extension
  distDir: "out",
  trailingSlash: true,
  images: { unoptimized: true },
  experimental: {
    turbo: undefined,        // Disable Turbopack — has a bug with static export
  },
};

module.exports = nextConfig;
