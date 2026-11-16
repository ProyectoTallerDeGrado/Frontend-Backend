import { defineConfig, devices } from "@playwright/test";

/**
 * Pruebas de punta a punta de la web. Necesitan el backend arriba **con los datos de
 * demostración** (`uv run python -m emprendeu.db.seed`) y `API_URL` apuntándole:
 *
 *   API_URL=http://localhost:8000/api/v1 pnpm test:e2e
 *
 * Playwright levanta la web en el puerto 3100 (no pisa a `pnpm dev`).
 */
const PORT = 3100;

export default defineConfig({
  testDir: "./e2e",
  timeout: 60_000,
  fullyParallel: false,
  workers: 1,
  reporter: [["list"]],
  use: { baseURL: `http://localhost:${PORT}`, trace: "retain-on-failure", locale: "es-BO" },
  // `channel: "chromium"` usa el Chromium completo (modo headless nuevo): una sola descarga.
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"], channel: "chromium" } }],
  webServer: {
    command: `pnpm dev --port ${PORT}`,
    url: `http://localhost:${PORT}/login`,
    reuseExistingServer: true,
    timeout: 120_000,
    env: { API_URL: process.env.API_URL ?? "http://localhost:8000/api/v1" },
  },
});
