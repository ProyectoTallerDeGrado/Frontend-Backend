"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

export async function updateChallengeXpAction(
  retoId: number,
  xp: number,
): Promise<{ ok: boolean; message: string }> {
  try {
    await authedFetch(`/challenges/${retoId}`, { method: "PATCH", body: { xp_recompensa: Math.max(0, xp) } });
  } catch (error) {
    const denied = error instanceof ApiError && error.status === 403;
    return { ok: false, message: denied ? "No tienes permiso para esta acción." : "No se pudo actualizar el XP." };
  }
  revalidatePath("/catalogs");
  return { ok: true, message: "Recompensa actualizada. Registrado en auditoría." };
}

export async function updateChallengeEvidenceAction(
  retoId: number,
  requiereEvidencia: boolean,
): Promise<{ ok: boolean; message: string }> {
  try {
    await authedFetch(`/challenges/${retoId}`, {
      method: "PATCH",
      body: { requiere_evidencia: requiereEvidencia },
    });
  } catch (error) {
    const denied = error instanceof ApiError && error.status === 403;
    return { ok: false, message: denied ? "No tienes permiso para esta acción." : "No se pudo actualizar el reto." };
  }
  revalidatePath("/catalogs");
  return { ok: true, message: "Reto actualizado. Registrado en auditoría." };
}
