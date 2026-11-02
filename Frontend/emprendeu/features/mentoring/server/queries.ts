import "server-only";

import { authedFetch } from "@/features/auth";

import {
  assignmentSchema,
  availabilitySchema,
  historyEventSchema,
  mentorSchema,
  sessionPageSchema,
  sessionSchema,
} from "../schemas/mentoring-schemas";
import type { Assignment, Availability, HistoryEvent, Mentor, Session, SessionFilters } from "../types";

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

/** Todas las sesiones (coordinación y administración), paginadas. */
export async function listSessions(filters: SessionFilters) {
  const search = filterParams(filters);
  search.set("page", String(filters.page ?? 1));
  search.set("page_size", String(SESSIONS_PAGE_SIZE));
  return sessionPageSchema.parse(await authedFetch(`/mentoring/sessions?${search}`));
}

/** CU19 · Línea de tiempo del emprendimiento (el backend aplica los permisos por emprendimiento). */
export async function getVentureHistory(ventureId: number, orden: "asc" | "desc"): Promise<HistoryEvent[]> {
  return historyEventSchema.array().parse(await authedFetch(`/mentoring/ventures/${ventureId}/history?orden=${orden}`));
}
