# WorldPath Group - CRITICAL FIX: registration was failing for anyone
# whose photo was bigger than 1MB (a normal phone photo easily exceeds
# this). Next.js defaults Server Actions to a 1MB body limit; this raises
# it to 10mb to match the app's own 5MB upload limit.
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'

@'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Server Actions default to a 1MB request body limit, which is too small
  // for the photo/document uploads this app requires (up to 5MB — see
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

'@ | Set-Content -LiteralPath "next.config.ts" -Encoding utf8

git add .
git commit -m "Fix: raise Server Actions body size limit so photo uploads on registration stop failing"
git push

Write-Host 'Done. Files written and pushed.'