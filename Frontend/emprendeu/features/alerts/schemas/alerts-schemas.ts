import { z } from "zod";

export const trackingSettingsSchema = z.object({
  inactividad_dias: z.number(),
  caida_sentimiento_pct: z.number(),
  periodos_consecutivos: z.number(),
  notificar_coordinador: z.boolean(),
  notificar_asesor: z.boolean(),
  alertar_incumplimiento: z.boolean(),
  fecha_actualizacion: z.string().nullable(),
});

export const evaluationSchema = z.object({
  creadas: z.number(),
  por_tipo: z.record(z.string(), z.number()),
});
