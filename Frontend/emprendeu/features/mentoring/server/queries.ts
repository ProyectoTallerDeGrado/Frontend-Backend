import "server-only";

import { authedFetch } from "@/features/auth";
import { boDay } from "@/lib/format";

import {
  assignmentSchema,
  availabilitySchema,
  historyEventSchema,
  commitmentSchema,
  mentorSchema,
  progressSummarySchema,
  recommendationSchema,
  sessionPageSchema,
  sessionSchema,
} from "../schemas/mentoring-schemas";
import type {
  Assignment,
  Availability,
  HistoryEvent,
  HistoryFilters,
  Mentor,
  ProgressSummary,
  Recommendation,
  Session,
  SessionFilters,
  VentureCommitment,
} from "../types";

export const SESSIONS_PAGE_SIZE = 20;

/** Todos los asesores con su estado de habilitación (vista del personal). */
export async function listAdvisors(): Promise<Mentor[]> {
  return mentorSchema.array().parse(await authedFetch("/mentoring/mentors"));
}

export async function listAssignments(): Promise<Assignment[]> {
  return assignmentSchema.array().parse(await authedFetch("/mentoring/assignments"));
}

/** Asignaciones del asesor de la sesión. */
export async function listMyAssignments(): Promise<Assignment[]> {
  return assignmentSchema.array().parse(await authedFetch("/mentoring/assignments/me"));
}

export async function getAvailability(mentorId: number): Promise<Availability[]> {
  return availabilitySchema.array().parse(await authedFetch(`/mentoring/mentors/${mentorId}/availability`));
}

function filterParams(filters: SessionFilters): URLSearchParams {
  const search = new URLSearchParams();
  if (filters.estado) search.set("estado", filters.estado);
  if (filters.desde) search.set("desde", filters.desde);
  if (filters.hasta) search.set("hasta", filters.hasta);
  return search;
}

/** Sesiones donde participa quien inició sesión (asesor), por estado y periodo. */
export async function listMySessions(filters: SessionFilters): Promise<Session[]> {
  return sessionSchema.array().parse(await authedFetch(`/mentoring/sessions/me?${filterParams(filters)}`));
}

/** Datos y reloj capturados juntos para que el dashboard del asesor renderice una instantánea consistente. */
export async function getAdvisorDashboardSnapshot() {
  const [sessions, assignments] = await Promise.all([listMySessions({}), listMyAssignments()]);
  return {
    sessions,
    assignments,
    generatedAt: Date.now(),
    currentMonth: boDay().slice(0, 7),
  };
}

/** Todas las sesiones (coordinación y administración), paginadas. */
export async function listSessions(filters: SessionFilters) {
  const search = filterParams(filters);
  search.set("page", String(filters.page ?? 1));
  search.set("page_size", String(SESSIONS_PAGE_SIZE));
  return sessionPageSchema.parse(await authedFetch(`/mentoring/sessions?${search}`));
}

/** CU19 · Línea de tiempo del emprendimiento (el backend aplica los permisos por emprendimiento). */
export async function getVentureHistory(ventureId: number, filters: HistoryFilters): Promise<HistoryEvent[]> {
  const search = new URLSearchParams({ orden: filters.orden });
  for (const tipo of filters.tipos) search.append("tipo", tipo);
  if (filters.desde) search.set("desde", filters.desde);
  if (filters.hasta) search.set("hasta", filters.hasta);
  return historyEventSchema.array().parse(await authedFetch(`/mentoring/ventures/${ventureId}/history?${search}`));
}

/** CU17 · Recomendaciones del emprendimiento. */
export async function listVentureRecommendations(ventureId: number): Promise<Recommendation[]> {
  return recommendationSchema.array().parse(await authedFetch(`/mentoring/ventures/${ventureId}/recommendations`));
}

/** CU18 · Compromisos del emprendimiento con su responsable. */
export async function listVentureCommitments(ventureId: number): Promise<VentureCommitment[]> {
  const rows = commitmentSchema.array().parse(await authedFetch(`/mentoring/ventures/${ventureId}/commitments`));
  const now = Date.now();
  return rows.map((c) => ({
    ...c,
    vencido: c.estado !== "cumplido" && c.fecha_limite !== null && new Date(c.fecha_limite).getTime() < now,
  }));
}

/** CU20 · Progreso derivado (hitos cumplidos y último avance reportado). */
export async function getProgressSummary(ventureId: number): Promise<ProgressSummary> {
  return progressSummarySchema.parse(await authedFetch(`/mentoring/ventures/${ventureId}/progress-summary`));
}
