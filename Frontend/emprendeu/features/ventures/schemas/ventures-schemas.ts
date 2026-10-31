import { z } from "zod";

export const stageSchema = z.object({
  etapa_id: z.number(),
  nombre: z.string(),
  descripcion: z.string().nullable(),
  criterios: z.string().nullable(),
  orden: z.number().nullable(),
  estado: z.string().nullable(),
});
