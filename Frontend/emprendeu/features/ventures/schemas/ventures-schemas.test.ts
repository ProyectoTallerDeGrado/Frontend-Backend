import { describe, expect, it } from "vitest";

import { VENTURE_STATES, ventureFormSchema, ventureSchema } from "./ventures-schemas";

describe("ventureFormSchema (CU05)", () => {
  const ok = { name: "Sabores", description: "", sector: "", entrepreneurId: 3, estado: "activo" };

  it("exige un nombre de hasta 160 caracteres", () => {
    expect(ventureFormSchema.safeParse(ok).success).toBe(true);
    expect(ventureFormSchema.safeParse({ ...ok, name: "  " }).success).toBe(false);
    expect(ventureFormSchema.safeParse({ ...ok, name: "x".repeat(161) }).success).toBe(false);
  });

  it("el emprendedor es opcional al editar y positivo al crear", () => {
    expect(ventureFormSchema.safeParse({ ...ok, entrepreneurId: null }).success).toBe(true);
    expect(ventureFormSchema.safeParse({ ...ok, entrepreneurId: 0 }).success).toBe(false);
    expect(ventureFormSchema.safeParse({ ...ok, entrepreneurId: 1.5 }).success).toBe(false);
  });

  it("conoce los estados que fija la coordinación", () => {
    expect(VENTURE_STATES).toEqual(["activo", "pausado", "cerrado"]);
  });
});

describe("ventureSchema", () => {
  it("acepta un emprendimiento sin etapa todavía", () => {
    const parsed = ventureSchema.parse({
      emprendimiento_id: 1,
      nombre: "Sabores",
      descripcion: null,
      sector: null,
      estado: "activo",
      fecha_creacion: null,
      etapa_actual: null,
    });
    expect(parsed.etapa_actual).toBeNull();
  });
});
