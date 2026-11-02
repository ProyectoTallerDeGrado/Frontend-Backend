"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import { ventureFormSchema } from "../schemas/ventures-schemas";

export async function setStageStateAction(
  etapaId: number,
  estado: "activa" | "inactiva",
  name: string,
): Promise<{ ok: boolean; message: string }> {
  try {
    await authedFetch(`/stages/${etapaId}`, { method: "PATCH", body: { estado } });
  } catch (error) {
    const denied = error instanceof ApiError && error.status === 403;
    return { ok: false, message: denied ? "No tienes permiso para esta acción." : "No se pudo actualizar la etapa." };
  }
  revalidatePath("/catalogs");
  return { ok: true, message: `Etapa ${estado === "activa" ? "activada" : "desactivada"}: ${name}.` };
}

/** CU12: avanza el emprendimiento a la etapa siguiente (el backend rechaza saltos y retrocesos). */
export async function advanceVentureStageAction(
  ventureId: number,
  stageId: number,
  observaciones: string,
  name: string,
): Promise<{ ok: boolean; message: string }> {
  try {
    await authedFetch(`/ventures/${ventureId}/stage`, {
      method: "PUT",
      body: { etapa_id: stageId, observaciones: observaciones.trim() || null },
    });
  } catch (error) {
    if (error instanceof ApiError) {
      if (error.code === "invalid_stage_transition") return { ok: false, message: error.message };
      if (error.code === "stage_inactive") return { ok: false, message: "Esa etapa está inactiva." };
      if (error.status === 403) return { ok: false, message: "No tienes permiso para cambiar la etapa." };
    }
    return { ok: false, message: "No se pudo cambiar la etapa. Intenta de nuevo." };
  }
  revalidatePath("/ventures");
  return { ok: true, message: `Etapa actualizada: ${name}. Registrado en auditoría.` };
}

type VentureInput = {
  name: string;
  description: string;
  sector: string;
  entrepreneurId: number | null;
  estado: string;
};

function ventureMessage(error: unknown, fallback: string): string {
  if (error instanceof ApiError) {
    if (error.code === "entrepreneur_required") return "Elige al emprendedor al que pertenece el emprendimiento.";
    if (error.code === "reserved_fields") return "Ese campo solo lo cambia la coordinación.";
    if (error.status === 403) return "No tienes permiso para esta acción.";
  }
  return fallback;
}

/** CU05: la coordinación crea el emprendimiento de un emprendedor concreto. */
export async function createVentureAction(input: VentureInput): Promise<{ ok: boolean; message: string }> {
  const parsed = ventureFormSchema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues[0]?.message ?? "Revisa los datos." };
  if (parsed.data.entrepreneurId === null) return { ok: false, message: "Elige al emprendedor." };
  try {
    await authedFetch("/ventures", {
      method: "POST",
      body: {
        nombre: parsed.data.name,
        descripcion: parsed.data.description || null,
        sector: parsed.data.sector || null,
        emprendedor_id: parsed.data.entrepreneurId,
      },
    });
  } catch (error) {
    return { ok: false, message: ventureMessage(error, "No se pudo crear el emprendimiento. Intenta de nuevo.") };
  }
  revalidatePath("/ventures");
  return { ok: true, message: `Emprendimiento creado: ${parsed.data.name}.` };
}

/** CU05: edita los datos del emprendimiento; el estado es un campo reservado a la coordinación. */
export async function updateVentureAction(
  ventureId: number,
  input: VentureInput,
): Promise<{ ok: boolean; message: string }> {
  const parsed = ventureFormSchema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues[0]?.message ?? "Revisa los datos." };
  try {
    await authedFetch(`/ventures/${ventureId}`, {
      method: "PATCH",
      body: {
        nombre: parsed.data.name,
        descripcion: parsed.data.description || null,
        sector: parsed.data.sector || null,
        estado: parsed.data.estado || undefined,
      },
    });
  } catch (error) {
    return { ok: false, message: ventureMessage(error, "No se pudo guardar. Intenta de nuevo.") };
  }
  revalidatePath("/ventures");
  return { ok: true, message: `Emprendimiento actualizado: ${parsed.data.name}.` };
}
