import "server-only";

import { authedFetch } from "@/features/auth";

import { trackingSettingsSchema } from "../schemas/alerts-schemas";
import type { TrackingSettings } from "../types";

export async function getTrackingSettings(): Promise<TrackingSettings> {
  const s = trackingSettingsSchema.parse(await authedFetch("/alerts/settings"));
  return {
    inactividad_dias: s.inactividad_dias,
    caida_sentimiento_pct: s.caida_sentimiento_pct,
    periodos_consecutivos: s.periodos_consecutivos,
    notificar_coordinador: s.notificar_coordinador,
    notificar_asesor: s.notificar_asesor,
    alertar_incumplimiento: s.alertar_incumplimiento,
  };
}
