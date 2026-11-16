import { describe, expect, it } from "vitest";

import { parseHistoryFilters } from "./history-filters";

describe("parseHistoryFilters (CU19)", () => {
  it("sin parámetros usa el orden ascendente y no filtra", () => {
    expect(parseHistoryFilters({})).toEqual({ orden: "asc", tipos: [], desde: undefined, hasta: undefined });
  });

  it("descarta tipos y fechas inválidos y repetidos", () => {
    const parsed = parseHistoryFilters({ tipo: ["sesion", "inventado", "sesion"], desde: "2026-13-xx", hasta: "2026-11-05", orden: "desc" });
    expect(parsed.tipos).toEqual(["sesion"]);
    expect(parsed.desde).toBeUndefined();
    expect(parsed.hasta).toBe("2026-11-05");
    expect(parsed.orden).toBe("desc");
  });

  it("acepta un solo tipo como texto", () => {
    expect(parseHistoryFilters({ tipo: "hito" }).tipos).toEqual(["hito"]);
  });
});
