import { z } from "zod";

export const stageSchema = z.object({
  etapa_id: z.number(),
  nombre: z.string(),
  descripcion: z.string().nullable(),
  criterios: z.string().nullable(),
  orden: z.number().nullable(),
  estado: z.string().nullable(),
});

/** Página de `GET /ventures` (solo lo que usan las listas de selección). */
export const ventureOptionsSchema = z.object({
  items: z.array(z.object({ emprendimiento_id: z.number(), nombre: z.string() })),
});

export const ventureSchema = z.object({
  emprendimiento_id: z.number(),
  nombre: z.string(),
  descripcion: z.string().nullable(),
  sector: z.string().nullable(),
  estado: z.string().nullable(),
  fecha_creacion: z.string().nullable(),
  etapa_actual: stageSchema.nullable(),
});

export const venturePageSchema = z.object({
  items: z.array(ventureSchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});

export const stepSchema = z.object({
  emprendimiento_etapa_id: z.number(),
  etapa_id: z.number(),
  etapa: z.string(),
  estado: z.string().nullable(),
  fecha_inicio: z.string().nullable(),
  fecha_fin: z.string().nullable(),
  observaciones: z.string().nullable(),
});

export const VENTURE_STATES = ["activo", "pausado", "cerrado"] as const;

/** Formulario de emprendimiento (alta y edición por la coordinación). */
export const ventureFormSchema = z.object({
  name: z.string().trim().min(1, "Ingresa el nombre del emprendimiento.").max(160, "Máximo 160 caracteres."),
  description: z.string().trim(),
  sector: z.string().trim().max(120, "Máximo 120 caracteres."),
  entrepreneurId: z.number().int().positive("Elige al emprendedor.").nullable(),
  estado: z.string().trim().max(40),
});
