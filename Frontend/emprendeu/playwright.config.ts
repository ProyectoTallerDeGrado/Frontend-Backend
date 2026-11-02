import { defineConfig } from "@playwright/test";

/**
 * Pruebas de extremo a extremo con navegador real contra la web y la API ya levantadas.
 *
 *   E2E_BASE_URL=http://127.0.0.1:3000 \
 *   E2E_API_URL=http://127.0.0.1:8000/api/v1 \
 *   E2E_ADMIN_EMAIL=admin@correo.com E2E_ADMIN_PASSWORD=... \
 *   pnpm e2e
 *
 * `global-setup.ts` usa la cuenta de administrador para crear a las personas de la prueba.
 */
export default defineConfig({
  testDir: "./e2e",
  globalSetup: "./e2e/global-setup.ts",
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 45_000,
  reporter: [["list"]],
  use: {
    baseURL: process.env.E2E_BASE_URL ?? "http://127.0.0.1:3000",
    locale: "es-BO",
    timezoneId: "America/La_Paz",
    trace: "retain-on-failure",
  },
});
