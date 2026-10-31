import { z } from "zod";

export const auditEntrySchema = z.object({
  bitacora_id: z.number(),
  fecha: z.string().nullable(),
  actor_id: z.number().nullable(),
  actor: z.string().nullable(),
  accion: z.string(),
  categoria: z.string(),
  descripcion: z.string(),
  objeto: z.string().nullable(),
  resultado: z.string(),
});

export const auditPageSchema = z.object({
  items: z.array(auditEntrySchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});
