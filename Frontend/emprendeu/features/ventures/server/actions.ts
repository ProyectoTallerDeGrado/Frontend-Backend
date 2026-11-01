"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

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
