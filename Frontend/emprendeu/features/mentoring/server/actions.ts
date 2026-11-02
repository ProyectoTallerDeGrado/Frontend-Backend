"use server";

import { revalidatePath } from "next/cache";
import type { z } from "zod";

import { authedFetch } from "@/features/auth";
import { ApiError } from "@/lib/api-client";
import { toBoIso } from "@/lib/format";

import {
  availabilityInputSchema,
  commitmentInputSchema,
  recommendationInputSchema,
  registerSessionInputSchema,
  sessionInputSchema,
} from "../schemas/mentoring-schemas";
import type { ActionResult } from "../types";

const MESSAGES: Record<string, string> = {
  availability_overlap: "Ese horario se solapa con otro que ya tienes. No se guardó nada.",
  availability_not_found: "Ese horario ya no existe.",
  mentor_not_enabled: "El asesor no está habilitado.",
  assignment_exists: "Ese asesor ya está asignado a ese emprendimiento.",
  not_assigned: "No estás asignado a ese emprendimiento.",
  session_mismatch: "La sesión no es de ese emprendimiento.",
  responsible_not_member: "El responsable debe ser un emprendedor del emprendimiento o un asesor asignado.",
  future_date: "La fecha realizada no puede estar en el futuro.",
  session_closed: "La sesión ya no admite cambios.",
};

function fail(error: unknown): ActionResult {
  if (error instanceof ApiError) {
    const known = MESSAGES[error.code];
    if (known) return { ok: false, message: known };
    if (error.status === 403) return { ok: false, message: "No tienes permiso para esta acción." };
    if (error.status >= 500 || error.status === 0) {
      return { ok: false, message: "No se pudo completar la acción. Intenta de nuevo." };
    }
    return { ok: false, message: error.message };
  }
  return { ok: false, message: "Ocurrió un error inesperado." };
}

/** Primer mensaje de un fallo de validación, listo para mostrar. */
function invalid(error: z.ZodError): ActionResult {
  return { ok: false, message: error.issues[0]?.message ?? "Revisa los datos del formulario." };
}

async function run(
  call: () => Promise<unknown>,
  paths: string[],
  message: string,
): Promise<ActionResult> {
  try {
    await call();
  } catch (error) {
    return fail(error);
  }
  for (const path of paths) revalidatePath(path);
  return { ok: true, message };
}

// --- CU09 · Asignar asesor (coordinación) ------------------------------------------

export async function setAdvisorEnabledAction(
  mentorId: number,
  habilitado: boolean,
  name: string,
): Promise<ActionResult> {
  return run(
    () => authedFetch(`/mentoring/mentors/${mentorId}/enabled`, { method: "PUT", body: { habilitado } }),
    ["/mentoring/assignments"],
    `${habilitado ? "Asesor habilitado" : "Asesor inhabilitado"}: ${name}. Registrado en auditoría.`,
  );
}

export async function assignAdvisorAction(mentorId: number, ventureId: number): Promise<ActionResult> {
  if (!Number.isInteger(mentorId) || !Number.isInteger(ventureId)) {
    return { ok: false, message: "Elige un asesor y un emprendimiento." };
  }
  return run(
    () =>
      authedFetch("/mentoring/assignments", {
        method: "POST",
        body: { usuario_id: mentorId, emprendimiento_id: ventureId },
      }),
    ["/mentoring/assignments"],
    "Asesor asignado. Registrado en auditoría.",
  );
}

export async function endAssignmentAction(assignmentId: number): Promise<ActionResult> {
  return run(
    () => authedFetch(`/mentoring/assignments/${assignmentId}/end`, { method: "PATCH" }),
    ["/mentoring/assignments"],
    "Asignación finalizada.",
  );
}

// --- CU15 · Disponibilidad del asesor ----------------------------------------------

export async function addAvailabilityAction(
  mentorId: number,
  input: { date: string; start: string; end: string },
): Promise<ActionResult> {
  const parsed = availabilityInputSchema.safeParse(input);
  if (!parsed.success) return invalid(parsed.error);
  const { date, start, end } = parsed.data;
  return run(
    () =>
      authedFetch(`/mentoring/mentors/${mentorId}/availability`, {
        method: "POST",
        body: { fecha_inicio: toBoIso(date, start), fecha_fin: toBoIso(date, end) },
      }),
    ["/mentoring/availability"],
    "Horario agregado.",
  );
}

export async function setAvailabilityStateAction(
  id: number,
  estado: "disponible" | "bloqueado",
): Promise<ActionResult> {
  return run(
    () => authedFetch(`/mentoring/availability/${id}`, { method: "PATCH", body: { estado } }),
    ["/mentoring/availability"],
    estado === "bloqueado" ? "Horario bloqueado: no se ofrecerá para agendar." : "Horario disponible de nuevo.",
  );
}

export async function deleteAvailabilityAction(id: number): Promise<ActionResult> {
  return run(
    () => authedFetch(`/mentoring/availability/${id}`, { method: "DELETE" }),
    ["/mentoring/availability"],
    "Horario eliminado.",
  );
}

// --- CU16 · Sesiones realizadas ----------------------------------------------------

export async function registerSessionAction(input: {
  ventureId: number;
  date: string;
  time: string;
  tema: string;
  modalidad: string;
  observaciones: string;
}): Promise<ActionResult> {
  const parsed = registerSessionInputSchema.safeParse(input);
  if (!parsed.success) return invalid(parsed.error);
  const v = parsed.data;
  return run(
    () =>
      authedFetch("/mentoring/sessions/register", {
        method: "POST",
        body: {
          emprendimiento_id: v.ventureId,
          fecha_realizada: toBoIso(v.date, v.time),
          tema: v.tema,
          modalidad: v.modalidad,
          observaciones: v.observaciones || null,
        },
      }),
    ["/mentoring/sessions"],
    "Sesión registrada.",
  );
}

export async function completeSessionAction(
  sessionId: number,
  input: { date: string; time: string; tema: string; modalidad: string; observaciones: string },
): Promise<ActionResult> {
  const parsed = sessionInputSchema.safeParse(input);
  if (!parsed.success) return invalid(parsed.error);
  const v = parsed.data;
  return run(
    () =>
      authedFetch(`/mentoring/sessions/${sessionId}/complete`, {
        method: "POST",
        body: {
          fecha_realizada: toBoIso(v.date, v.time),
          tema: v.tema,
          modalidad: v.modalidad,
          observaciones: v.observaciones || null,
        },
      }),
    ["/mentoring/sessions"],
    "Sesión registrada como realizada.",
  );
}

// --- CU17 · Recomendaciones · CU18 · Compromisos -----------------------------------

export async function recommendAction(input: {
  ventureId: number;
  sessionId: number | null;
  titulo: string;
  contenido: string;
}): Promise<ActionResult> {
  const parsed = recommendationInputSchema.safeParse(input);
  if (!parsed.success) return invalid(parsed.error);
  const v = parsed.data;
  return run(
    () =>
      authedFetch("/mentoring/recommendations", {
        method: "POST",
        body: {
          emprendimiento_id: v.ventureId,
          sesion_id: v.sessionId,
          titulo: v.titulo,
          contenido: v.contenido,
        },
      }),
    ["/mentoring/sessions"],
    "Recomendación registrada.",
  );
}

export async function commitAction(input: {
  ventureId: number;
  sessionId: number | null;
  responsibleId: number;
  descripcion: string;
  dueDate: string;
}): Promise<ActionResult> {
  const parsed = commitmentInputSchema.safeParse(input);
  if (!parsed.success) return invalid(parsed.error);
  const v = parsed.data;
  return run(
    () =>
      authedFetch("/mentoring/commitments", {
        method: "POST",
        body: {
          emprendimiento_id: v.ventureId,
          sesion_id: v.sessionId,
          usuario_id: v.responsibleId,
          descripcion: v.descripcion,
          // Sin fecha, el backend usa `dias_limite_compromiso`; con fecha, al final del día en Bolivia.
          fecha_limite: v.dueDate ? toBoIso(v.dueDate, "23:59") : null,
        },
      }),
    ["/mentoring/sessions"],
    "Compromiso registrado.",
  );
}
