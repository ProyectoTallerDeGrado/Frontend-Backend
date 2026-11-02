import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    // La carga de documentos de conocimiento llega por una server action: el backend acepta
    // hasta 10 MB y el formulario multipart agrega unos KB de sobrecosto.
    serverActions: { bodySizeLimit: "11mb" },
  },
};

export default nextConfig;
