import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Server Actions default to a 1MB request body limit, which is too small
  // for the photo/document uploads this app requires (up to 5MB â€” see
  // src/lib/uploads.ts). Without raising this, any registration or upload
  // with a normal phone photo attached fails with a 413 error.
  experimental: {
    serverActions: {
      bodySizeLimit: "10mb",
      allowedOrigins: ["worldpathgroup.org", "www.worldpathgroup.org", "worldpath-production.up.railway.app"],
    },
  },
};

export default nextConfig;

