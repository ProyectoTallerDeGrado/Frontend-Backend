import "server-only";

import { authedFetch } from "@/features/auth";

import { alertPageSchema, trackingSettingsSchema } from "../schemas/alerts-schemas";
import type { AlertFilters, TrackingSettings } from "../types";

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
