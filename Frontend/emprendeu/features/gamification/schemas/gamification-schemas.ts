import { z } from "zod";

export const challengeSchema = z.object({
  reto_id: z.number(),
  titulo: z.string(),
  descripcion: z.string().nullable(),
  tipo: z.string().nullable(),
  etapa_id: z.number(),
  etapa: z.string().nullable(),
  orden: z.number().nullable(),
  xp_recompensa: z.number(),
  estado: z.string().nullable(),
});

export const badgeSchema = z.object({
  insignia_id: z.number(),
  nombre: z.string(),
  criterio: z.string().nullable(),
  xp_recompensa: z.number(),
  estado: z.string().nullable(),
});

export const journeySchema = z.object({
  emprendimiento_id: z.number(),
  xp_total: z.number(),
  nivel: z.number(),
  xp_siguiente_nivel: z.number().nullable(),
  xp_faltante: z.number().nullable(),
  progreso_pct: z.number(),
  insignias: z.array(
    z.object({
      insignia_id: z.number(),
      nombre: z.string(),
      criterio: z.string().nullable(),
      xp_recompensa: z.number(),
      obtenida: z.boolean(),
      fecha_obtenida: z.string().nullable(),
    }),
  ),
  historial: z.array(
    z.object({ motivo: z.string().nullable(), cantidad: z.number(), fecha: z.string().nullable() }),
  ),
  etapas: z.array(
    z.object({ etapa_id: z.number(), nombre: z.string(), estado: z.enum(["cumplida", "en_curso", "bloqueada"]) }),
  ),
  retos: z.array(
    z.object({
      reto_id: z.number(),
      titulo: z.string(),
      descripcion: z.string().nullable(),
      etapa_id: z.number().nullable(),
      etapa: z.string().nullable(),
      orden: z.number().nullable(),
      xp_recompensa: z.number(),
      estado: z.enum(["cumplido", "en_curso", "bloqueado"]),
      fecha_completado: z.string().nullable(),
    }),
  ),
});
