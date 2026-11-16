import type { NextConfig } from "next";

/** Cabeceras de seguridad para todas las respuestas. */
const SECURITY_HEADERS = [
  // La web no se incrusta en marcos de otros sitios (clickjacking).
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
  ...(process.env.NODE_ENV === "production"
    ? [{ key: "Strict-Transport-Security", value: "max-age=31536000; includeSubDomains" }]
    : []),
];

const nextConfig: NextConfig = {
  async headers() {
    return [{ source: "/:path*", headers: SECURITY_HEADERS }];
  },
  experimental: {
    // La carga de documentos de conocimiento llega por una server action: el backend acepta
    // hasta 10 MB y el formulario multipart agrega unos KB de sobrecosto.
    serverActions: { bodySizeLimit: "11mb" },
  },
};

export default nextConfig;
