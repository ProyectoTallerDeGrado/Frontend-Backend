import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

/** Pruebas unitarias de esquemas y utilidades (lo que no necesita backend ni navegador). */
export default defineConfig({
  resolve: { alias: { "@": fileURLToPath(new URL("./", import.meta.url)) } },
  test: { environment: "node", include: ["**/*.test.ts"], exclude: ["node_modules/**", ".next/**", "e2e/**"] },
});
