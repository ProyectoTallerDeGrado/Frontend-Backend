import { fileURLToPath } from "node:url";

import { defineConfig } from "vitest/config";

/** Pruebas unitarias de lo que no necesita navegador: esquemas zod y utilidades de `lib/`. */
export default defineConfig({
  resolve: { alias: { "@": fileURLToPath(new URL(".", import.meta.url)) } },
  test: {
    environment: "node",
    include: ["lib/**/*.test.ts", "features/**/*.test.ts"],
  },
});
