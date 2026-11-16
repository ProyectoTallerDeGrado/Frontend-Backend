import type { MetadataRoute } from "next";

import { env } from "@/lib/env";

/** Solo la portada y la postulación son públicas; el resto es el panel del personal. */
export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: ["/$", "/apply"], disallow: "/" },
    sitemap: `${env.siteUrl}/sitemap.xml`,
  };
}
