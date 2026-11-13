import "server-only";

import { authedFetch } from "@/features/auth";

import { alertPageSchema, alertSchema, trackingSettingsSchema } from "../schemas/alerts-schemas";
import { ApiError } from "@/lib/api-client";
import type { Alert, AlertFilters, TrackingSettings } from "../types";

export const ALERTS_PAGE_SIZE = 20;

export async function getTrackingSettings(): Promise<TrackingSettings> {
  const s = trackingSettingsSchema.parse(await authedFetch("/alerts/settings"));
  return {
    inactividad_dias: s.inactividad_dias,
    caida_sentimiento_pct: s.caida_sentimiento_pct,
    periodos_consecutivos: s.periodos_consecutivos,
    notificar_coordinador: s.notificar_coordinador,
    notificar_asesor: s.notificar_asesor,
    alertar_incumplimiento: s.alertar_incumplimiento,
    dias_limite_compromiso: s.dias_limite_compromiso,
  };
}

/** Bandeja de alertas; el backend limita a un asesor a los emprendimientos que tiene asignados. */
export async function listAlerts(filters: AlertFilters) {
  const search = new URLSearchParams({ page: String(filters.page ?? 1), page_size: String(ALERTS_PAGE_SIZE) });
  if (filters.estado) search.set("estado", filters.estado);
  if (filters.tipo) search.set("tipo", filters.tipo);
  return alertPageSchema.parse(await authedFetch(`/alerts?${search}`));
}

/** CU13 · Detalle de una alerta (`null` si no existe o ya no está disponible para el usuario). */
export async function getAlert(alertId: number): Promise<Alert | null> {
  try {
    return alertSchema.parse(await authedFetch(`/alerts/${alertId}`));
  } catch (error) {
    if (error instanceof ApiError && (error.status === 404 || error.status === 403)) return null;
    throw error;
  }
}

/** Alertas abiertas para el contador del menú; ante cualquier fallo no se muestra nada. */
export async function countOpenAlerts(): Promise<number> {
  try {
    return alertPageSchema.parse(await authedFetch("/alerts?estado=abierta&page=1&page_size=1")).total;
  } catch {
    return 0;
  }
}
