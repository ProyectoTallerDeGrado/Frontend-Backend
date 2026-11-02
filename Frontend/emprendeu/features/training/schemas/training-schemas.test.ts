import { describe, expect, it } from "vitest";

import { MODALITIES, participantSchema, trainingFormSchema, trainingSchema } from "./training-schemas";

describe("trainingFormSchema (CU27)", () => {
  const ok = { titulo: "Finanzas", descripcion: "", fecha: "", modalidad: "", tipo: "" };

  it("solo exige el título; la fecha es opcional (hace falta para publicar)", () => {
    expect(trainingFormSchema.safeParse(ok).success).toBe(true);
    expect(trainingFormSchema.safeParse({ ...ok, titulo: "   " }).success).toBe(false);
    expect(trainingFormSchema.safeParse({ ...ok, titulo: "x".repeat(241) }).success).toBe(false);
  });

  it("limita la modalidad y el tipo", () => {
    expect(trainingFormSchema.safeParse({ ...ok, modalidad: "x".repeat(41) }).success).toBe(false);
    expect(trainingFormSchema.safeParse({ ...ok, tipo: "x".repeat(61) }).success).toBe(false);
    expect(MODALITIES).toContain("virtual");
  });
});

describe("respuestas del backend", () => {
  it("lee una capacitación con la asistencia propia opcional", () => {
    const base = {
      capacitacion_id: 1,
      titulo: "Finanzas",
      descripcion: null,
      fecha: null,
      modalidad: null,
      tipo: null,
      estado: "publicada",
      total_inscritos: 2,
    };
    expect(trainingSchema.parse(base).mi_asistencia).toBeUndefined();
    expect(trainingSchema.parse({ ...base, inscrito: true, mi_asistencia: false }).mi_asistencia).toBe(false);
  });

  it("distingue asistencia pendiente (null) de no asistió (false)", () => {
    const p = { capacitacion_participante_id: 1, emprendedor_id: 2, fecha_registro: null, nombre: "A", apellido: "B", email: null, documento_identidad: null };
    expect(participantSchema.parse({ ...p, asistencia: null }).asistencia).toBeNull();
    expect(participantSchema.parse({ ...p, asistencia: false }).asistencia).toBe(false);
  });
});
