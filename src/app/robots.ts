import type { MetadataRoute } from "next";

function siteUrl(): string {
  return (process.env.APP_URL || "http://localhost:3000").replace(/\/$/, "");
}

export default function robots(): MetadataRoute.Robots {
  const base = siteUrl();
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/admin", "/staff", "/student", "/api/", "/verify", "/register/check-email"],
    },
    sitemap: `${base}/sitemap.xml`,
  };
}
