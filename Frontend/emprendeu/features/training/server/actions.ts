"use server";

import { revalidatePath } from "next/cache";

import { authedFetch } from "@/features/auth";
import { searchEntrepreneurOptions } from "@/features/entrepreneurs";
import { ApiError } from "@/lib/api-client";
import { toBoIso } from "@/lib/format";

import { trainingInputSchema } from "../schemas/training-schemas";
import type { ActionResult, TrainingInput } from "../types";

const MESSAGES: Record<string, string> = {
  already_enrolled: "Ese emprendedor ya está inscrito en la capacitación.",
  training_not_found: "La capacitación ya no existe.",
  participant_not_found: "Ese emprendedor no participa en la capacitación.",
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

function body(input: TrainingInput) {
  const parsed = trainingInputSchema.safeParse(input);
  if (!parsed.success) return { error: parsed.error.issues[0]?.message ?? "Revisa los datos del formulario." };
  const v = parsed.data;
  return {
    value: {
      titulo: v.titulo,
      descripcion: v.descripcion || null,
      fecha: v.day ? toBoIso(v.day, v.time || "09:00") : null,
      modalidad: v.modalidad || null,
      tipo: v.tipo || null,
      ...(v.estado ? { estado: v.estado } : {}),
    },
  };
}

export async function createTrainingAction(input: TrainingInput): Promise<ActionResult> {
  const b = body(input);
  if (!b.value) return { ok: false, message: b.error };
  try {
    await authedFetch("/training", { method: "POST", body: b.value });
  } catch (error) {
    return fail(error);
  }
  revalidatePath("/training");
  return { ok: true, message: `Capacitación creada: ${b.value.titulo}.` };
}

export async function updateTrainingAction(id: number, input: TrainingInput): Promise<ActionResult> {
  const b = body(input);
  if (!b.value) return { ok: false, message: b.error };
  try {
    await authedFetch(`/training/${id}`, { method: "PATCH", body: b.value });
  } catch (error) {
    return fail(error);
  }
  revalidatePath("/training");
  revalidatePath(`/training/${id}`);
  return { ok: true, message: "Capacitación actualizada." };
}

export async function addParticipantAction(id: number, entrepreneurId: number): Promise<ActionResult> {
  if (!Number.isInteger(entrepreneurId) || entrepreneurId <= 0) return { ok: false, message: "Elige un emprendedor." };
  try {
    await authedFetch(`/training/${id}/participants`, { method: "POST", body: { emprendedor_id: entrepreneurId } });
  } catch (error) {
    return fail(error);
  }
  revalidatePath(`/training/${id}`);
  return { ok: true, message: "Participante agregado." };
}

export async function setAttendanceAction(id: number, entrepreneurId: number, attended: boolean): Promise<ActionResult> {
  try {
    await authedFetch(`/training/${id}/participants/${entrepreneurId}`, { method: "PATCH", body: { asistio: attended } });
  } catch (error) {
    return fail(error);
  }
  revalidatePath(`/training/${id}`);
  return { ok: true, message: attended ? "Asistencia registrada." : "Ausencia registrada." };
}

/** CU28: busca emprendedores para agregarlos a una capacitación (el backend limita los resultados). */
export async function searchEntrepreneursAction(q: string): Promise<{ id: number; name: string }[]> {
  try {
    return await searchEntrepreneurOptions(q);
  } catch {
    return [];
  }
}
