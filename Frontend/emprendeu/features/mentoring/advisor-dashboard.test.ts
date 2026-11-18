import { describe, expect, it } from "vitest";

import { summarizeAdvisorSnapshot } from "./advisor-dashboard";
import type { Assignment, Session } from "./types";

const NOW = Date.parse("2026-11-18T15:00:00Z"); // 11:00 en Bolivia
const MONTH = "2026-11";

function session(overrides: Partial<Session>): Session {
  return {
    sesion_id: 1,
    emprendimiento_id: 10,
    emprendimiento: "Café Andino",
    estado: "programada",
    tema: "Plan financiero",
    modalidad: "virtual",
    fecha_programada: "2026-11-20T14:00:00Z",
    fecha_realizada: null,
    observaciones: null,
    participantes: [],
    mentor: "Rodrigo",
    total_recomendaciones: 0,
    total_compromisos: 0,
    ...overrides,
  };
}

function assignment(overrides: Partial<Assignment>): Assignment {
  return {
    asignacion_id: 1,
    usuario_id: 5,
    usuario: "Rodrigo",
    emprendimiento_id: 10,
    emprendimiento: "Café Andino",
    tipo_asignacion: "Asesoría",
    estado: "activa",
    fecha_inicio: null,
    fecha_fin: null,
    ...overrides,
  };
}

describe("summarizeAdvisorSnapshot (dashboard del asesor)", () => {
  it("separa próximas sesiones de las pasadas que falta registrar", () => {
    const summary = summarizeAdvisorSnapshot({
      sessions: [
        session({ sesion_id: 1, fecha_programada: "2026-11-20T14:00:00Z" }),
        session({ sesion_id: 2, fecha_programada: "2026-11-10T14:00:00Z" }),
        session({ sesion_id: 3, fecha_programada: "2026-11-25T14:00:00Z" }),
      ],
      assignments: [],
      generatedAt: NOW,
      currentMonth: MONTH,
    });
    expect(summary.upcoming.map((s) => s.sesion_id)).toEqual([1, 3]);
    expect(summary.pendingResults.map((s) => s.sesion_id)).toEqual([2]);
  });

  it("cuenta realizadas del mes en hora de Bolivia y canceladas", () => {
    const summary = summarizeAdvisorSnapshot({
      sessions: [
        session({ sesion_id: 1, estado: "realizada", fecha_programada: null, fecha_realizada: "2026-11-03T13:00:00Z" }),
        // 02:00 UTC del 1 de diciembre = 30 de noviembre en Bolivia: sigue siendo noviembre.
        session({ sesion_id: 2, estado: "realizada", fecha_programada: null, fecha_realizada: "2026-12-01T02:00:00Z" }),
        // Mes anterior: no cuenta.
        session({ sesion_id: 3, estado: "realizada", fecha_programada: null, fecha_realizada: "2026-10-28T13:00:00Z" }),
        session({ sesion_id: 4, estado: "cancelada" }),
      ],
      assignments: [],
      generatedAt: NOW,
      currentMonth: MONTH,
    });
    expect(summary.completed).toHaveLength(3);
    expect(summary.completedThisMonth).toBe(2);
    expect(summary.cancelled).toBe(1);
  });

  it("suma compromisos y recomendaciones y solo cuenta asignaciones activas", () => {
    const summary = summarizeAdvisorSnapshot({
      sessions: [
        session({ sesion_id: 1, total_compromisos: 2, total_recomendaciones: 1 }),
        session({ sesion_id: 2, total_compromisos: 1, total_recomendaciones: 3 }),
      ],
      assignments: [assignment({ asignacion_id: 1 }), assignment({ asignacion_id: 2, estado: "finalizada" })],
      generatedAt: NOW,
      currentMonth: MONTH,
    });
    expect(summary.commitments).toBe(3);
    expect(summary.recommendations).toBe(4);
    expect(summary.activeAssignments.map((a) => a.asignacion_id)).toEqual([1]);
  });

  it("sin datos devuelve ceros y listas vacías", () => {
    const summary = summarizeAdvisorSnapshot({ sessions: [], assignments: [], generatedAt: NOW, currentMonth: MONTH });
    expect(summary.upcoming).toEqual([]);
    expect(summary.recent).toEqual([]);
    expect(summary.completedThisMonth).toBe(0);
  });
});
