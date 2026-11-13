"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import { evaluationSchema } from "../schemas/alerts-schemas";
import type { ActionResult, TrackingSettings } from "../types";

const FIELD_LABELS: Record<string, string> = {
  inactividad_dias: "Periodo de inactividad (1 a 365 días)",
  caida_sentimiento_pct: "Variación negativa mínima (1 a 100 %)",
  periodos_consecutivos: "Periodos consecutivos (1 a 12)",
  dias_limite_compromiso: "Plazo de los compromisos (1 a 90 días)",
};

function fail(error: unknown): ActionResult {
  if (error instanceof ApiError && error.status === 403) {
    return { ok: false, message: "No tienes permiso para esta acción." };
  }
  if (error instanceof ApiError && error.status === 422) {
    // El backend dice qué campo falló (`loc`); se nombra para que se sepa qué corregir.
    const first = Array.isArray(error.details) ? (error.details[0] as { loc?: unknown[] } | undefined) : undefined;
    const field = String(first?.loc?.at(-1) ?? "");
    const label = FIELD_LABELS[field];
    return {
      ok: false,
      message: label
        ? `«${label}» está fuera del rango permitido.`
        : "Algún valor está fuera del rango permitido.",
    };
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

const ALERT_MESSAGES: Record<string, string> = {
  alert_closed: "La alerta ya está cerrada y no se reabre.",
  alert_not_assigned: "Esa alerta es de un emprendimiento que no tienes asignado.",
};

/** CU13: marca una alerta como revisada, atendida o descartada (queda en la auditoría). */
export async function updateAlertAction(
  alertId: number,
  estado: "revisada" | "atendida" | "descartada",
): Promise<ActionResult> {
  try {
    await authedFetch(`/alerts/${alertId}`, { method: "PATCH", body: { estado } });
  } catch (error) {
    if (error instanceof ApiError && ALERT_MESSAGES[error.code]) {
      return { ok: false, message: ALERT_MESSAGES[error.code] };
    }
    return fail(error);
  }
  revalidatePath("/alerts");
  revalidatePath("/alerts/[id]", "page");
  revalidatePath("/", "layout"); // el contador de abiertas del menú
  const text = { revisada: "Alerta marcada como revisada.", atendida: "Alerta atendida.", descartada: "Alerta descartada." };
  return { ok: true, message: text[estado] };
}
