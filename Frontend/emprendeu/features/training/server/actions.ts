"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";
import { toBoIso } from "@/lib/format";

import { trainingFormSchema, type TrainingFormInput } from "../schemas/training-schemas";
import type { ActionResult } from "../types";

function fail(error: unknown, fallback: string): ActionResult {
  if (error instanceof ApiError) {
    switch (error.code) {
      case "date_required":
        return { ok: false, message: "Para publicar la capacitación define su fecha." };
      case "invalid_training_transition":
        return { ok: false, message: "Ese cambio de estado no está permitido." };
      case "training_closed":
        return { ok: false, message: "La capacitación ya terminó o fue cancelada y no se edita." };
      case "training_not_open":
        return { ok: false, message: "La capacitación debe estar publicada para registrar participantes o asistencia." };
      case "already_enrolled":
        return { ok: false, message: "Esa persona ya está inscrita en esta capacitación." };
      case "participant_not_found":
        return { ok: false, message: "No se encontró al participante." };
    }
    if (error.status === 403) return { ok: false, message: "Esta acción es de coordinación." };
  }
  return { ok: false, message: fallback };
}

function body(input: TrainingFormInput) {
  return {
    titulo: input.titulo,
    descripcion: input.descripcion || null,
    fecha: input.fecha ? toBoIso(...(input.fecha.split("T") as [string, string])) : null,
    modalidad: input.modalidad || null,
    tipo: input.tipo || null,
  };
}

/** CU27: crea la capacitación como borrador (nadie más la ve hasta publicarla). */
export async function createTrainingAction(input: TrainingFormInput): Promise<ActionResult> {
  const parsed = trainingFormSchema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues[0]?.message ?? "Revisa los datos." };
  try {
    await authedFetch("/training", { method: "POST", body: body(parsed.data) });
  } catch (error) {
    return fail(error, "No se pudo crear la capacitación. Intenta de nuevo.");
  }
  revalidatePath("/training");
  return { ok: true, message: `Capacitación creada como borrador: ${parsed.data.titulo}.` };
}

export async function updateTrainingAction(id: number, input: TrainingFormInput): Promise<ActionResult> {
  const parsed = trainingFormSchema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues[0]?.message ?? "Revisa los datos." };
  try {
    await authedFetch(`/training/${id}`, { method: "PATCH", body: body(parsed.data) });
  } catch (error) {
    return fail(error, "No se pudo guardar. Intenta de nuevo.");
  }
  revalidatePath("/training");
  return { ok: true, message: `Capacitación actualizada: ${parsed.data.titulo}.` };
}

const STATE_LABEL: Record<string, string> = {
  publicada: "publicada",
  realizada: "marcada como realizada",
  cancelada: "cancelada",
};

/** Publica, marca como realizada o cancela. */
export async function setTrainingStateAction(
  id: number,
  estado: "publicada" | "realizada" | "cancelada",
  title: string,
): Promise<ActionResult> {
  try {
    await authedFetch(`/training/${id}`, { method: "PATCH", body: { estado } });
  } catch (error) {
    return fail(error, "No se pudo cambiar el estado. Intenta de nuevo.");
  }
  revalidatePath("/training");
  revalidatePath(`/training/${id}/participants`);
  return { ok: true, message: `Capacitación ${STATE_LABEL[estado]}: ${title}.` };
}

/** CU28: agrega un participante; no se repite en la misma capacitación. */
export async function addParticipantAction(id: number, emprendedorId: number): Promise<ActionResult> {
  try {
    await authedFetch(`/training/${id}/participants`, { method: "POST", body: { emprendedor_id: emprendedorId } });
  } catch (error) {
    return fail(error, "No se pudo agregar al participante. Intenta de nuevo.");
  }
  revalidatePath(`/training/${id}/participants`);
  revalidatePath("/training");
  return { ok: true, message: "Participante agregado." };
}

export async function setAttendanceAction(
  id: number,
  emprendedorId: number,
  asistio: boolean,
  name: string,
): Promise<ActionResult> {
  try {
    await authedFetch(`/training/${id}/participants/${emprendedorId}`, { method: "PATCH", body: { asistio } });
  } catch (error) {
    return fail(error, "No se pudo registrar la asistencia. Intenta de nuevo.");
  }
  revalidatePath(`/training/${id}/participants`);
  return { ok: true, message: `${name}: ${asistio ? "asistió" : "no asistió"}.` };
}
