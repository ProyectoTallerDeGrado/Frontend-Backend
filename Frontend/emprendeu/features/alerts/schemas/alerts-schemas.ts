import { z } from "zod";

export const trackingSettingsSchema = z.object({
  inactividad_dias: z.number(),
  caida_sentimiento_pct: z.number(),
  periodos_consecutivos: z.number(),
  notificar_coordinador: z.boolean(),
  notificar_asesor: z.boolean(),
  alertar_incumplimiento: z.boolean(),
  dias_limite_compromiso: z.number(),
  fecha_actualizacion: z.string().nullable(),
});

export const evaluationSchema = z.object({
  creadas: z.number(),
  por_tipo: z.record(z.string(), z.number()),
});

export const alertSchema = z.object({
  alerta_id: z.number(),
  emprendimiento_id: z.number(),
  emprendimiento: z.string().nullable(),
  tipo: z.string().nullable(),
  titulo: z.string(),
  descripcion: z.string().nullable(),
  prioridad: z.string().nullable(),
  estado: z.string().nullable(),
  fecha_generacion: z.string().nullable(),
  atendida_por_id: z.number().nullable(),
  atendida_por: z.string().nullable(),
});

export const alertPageSchema = z.object({
  items: z.array(alertSchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});
