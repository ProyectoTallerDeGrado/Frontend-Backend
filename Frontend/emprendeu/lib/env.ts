import "server-only";

/** Variables de entorno del servidor, leídas una sola vez y con valor por defecto de desarrollo. */
export const env = {
  /** Base del contrato HTTP del backend (siempre bajo /api/v1). */
  apiUrl: (process.env.API_URL ?? "http://localhost:8000/api/v1").replace(/\/$/, ""),
  isProduction: process.env.NODE_ENV === "production",
  /** URL pública de la web (para Open Graph y enlaces absolutos). */
  siteUrl: (process.env.SITE_URL ?? "http://localhost:3000").replace(/\/$/, ""),
};
