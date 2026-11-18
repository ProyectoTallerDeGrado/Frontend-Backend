import { boDay } from "@/lib/format";

import type { Assignment, Session } from "./types";

/** Lo que el dashboard del asesor necesita para calcular sus cifras (una sola instantánea). */
export type AdvisorSnapshot = {
  sessions: Session[];
  assignments: Assignment[];
  /** Momento de la captura (ms). Separa «próximas» de «por registrar». */
  generatedAt: number;
  /** Mes en Bolivia como `AAAA-MM`. */
  currentMonth: string;
};

export type AdvisorSummary = {
  activeAssignments: Assignment[];
  upcoming: Session[];
  pendingResults: Session[];
  completed: Session[];
  completedThisMonth: number;
  cancelled: number;
  programmed: number;
  commitments: number;
  recommendations: number;
  recent: Session[];
};

/** Fecha de referencia de una sesión: la programada, o la realizada si no hay programada. */
export function sessionTime(session: Session): number {
  const value = session.fecha_programada ?? session.fecha_realizada;
  return value ? new Date(value).getTime() : 0;
}

/** Cuenta y ordena lo que el asesor ve en su panel (sin tocar la red ni el reloj). */
export function summarizeAdvisorSnapshot({ sessions, assignments, generatedAt, currentMonth }: AdvisorSnapshot): AdvisorSummary {
  const programmed = sessions.filter((session) => session.estado === "programada");
  const completed = sessions.filter((session) => session.estado === "realizada");
  const cancelled = sessions.filter((session) => session.estado === "cancelada");

  const upcoming = programmed
    .filter((session) => sessionTime(session) >= generatedAt)
    .sort((a, b) => sessionTime(a) - sessionTime(b));
  const pendingResults = programmed
    .filter((session) => sessionTime(session) > 0 && sessionTime(session) < generatedAt)
    .sort((a, b) => sessionTime(b) - sessionTime(a));

  const completedThisMonth = completed.filter((session) => {
    const when = session.fecha_realizada ?? session.fecha_programada;
    return when ? monthInBolivia(when) === currentMonth : false;
  });

  return {
    activeAssignments: assignments.filter((assignment) => assignment.estado === "activa"),
    upcoming,
    pendingResults,
    completed,
    completedThisMonth: completedThisMonth.length,
    cancelled: cancelled.length,
    programmed: programmed.length,
    commitments: sessions.reduce((total, session) => total + session.total_compromisos, 0),
    recommendations: sessions.reduce((total, session) => total + session.total_recomendaciones, 0),
    recent: [...sessions]
      .filter((session) => sessionTime(session) > 0)
      .sort((a, b) => sessionTime(b) - sessionTime(a))
      .slice(0, 5),
  };
}

/** Mes `AAAA-MM` de una fecha ISO en hora de Bolivia. */
function monthInBolivia(iso: string): string {
  return boDay(iso).slice(0, 7);
}
