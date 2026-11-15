import { describe, expect, it } from "vitest";

import { participantSchema, trainingInputSchema, trainingPageSchema } from "./training-schemas";

describe("trainingInputSchema (CU27)", () => {
  it("el título es obligatorio y se recorta", () => {
    expect(trainingInputSchema.safeParse({ titulo: "   " }).success).toBe(false);
    expect(trainingInputSchema.parse({ titulo: "  Finanzas  " }).titulo).toBe("Finanzas");
  });

  it("solo admite los estados del backend", () => {
    expect(trainingInputSchema.safeParse({ titulo: "X", estado: "programada" }).success).toBe(true);
    expect(trainingInputSchema.safeParse({ titulo: "X", estado: "publicada" }).success).toBe(false);
  });
});

describe("respuestas del backend", () => {
  it("la asistencia puede estar sin registrar (null)", () => {
    const row = { capacitacion_participante_id: 1, emprendedor_id: 7, nombre: "Ana Prueba", asistencia: null, fecha_registro: null };
    expect(participantSchema.parse(row).asistencia).toBeNull();
  });

  it("la página de capacitaciones trae total y paginación", () => {
    const page = trainingPageSchema.parse({ items: [], page: 1, page_size: 20, total: 0 });
    expect(page.total).toBe(0);
  });
});
