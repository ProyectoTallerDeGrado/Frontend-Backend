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
