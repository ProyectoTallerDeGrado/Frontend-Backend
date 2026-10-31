"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import { evaluationSchema } from "../schemas/alerts-schemas";
import type { ActionResult, TrackingSettings } from "../types";

function fail(error: unknown): ActionResult {
  if (error instanceof ApiError && error.status === 403) {
    return { ok: false, message: "No tienes permiso para esta acción." };
  }
  if (error instanceof ApiError && error.status === 422) {
    return { ok: false, message: "Algún valor está fuera del rango permitido." };
  }
  return { ok: false, message: "No se pudo completar la acción. Intenta de nuevo." };
}

export async function saveTrackingSettingsAction(settings: TrackingSettings): Promise<ActionResult> {
  try {
    await authedFetch("/alerts/settings", { method: "PUT", body: settings });
  } catch (error) {
    return fail(error);
  }
  revalidatePath("/settings/tracking");
  return { ok: true, message: "Parámetros de seguimiento actualizados. Registrado en auditoría." };
}

export async function evaluateAlertsAction(): Promise<ActionResult> {
  try {
    const result = evaluationSchema.parse(await authedFetch("/alerts/evaluate", { method: "POST" }));
    return {
      ok: true,
      message:
        result.creadas === 0
          ? "Evaluación completa: no hay alertas nuevas."
          : `Evaluación completa: ${result.creadas} alerta(s) nueva(s).`,
    };
  } catch (error) {
    return fail(error);
  }
}
