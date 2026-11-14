import { z } from "zod";

/** Respuestas de `/training/*` según el OpenAPI del backend. */
export const trainingSchema = z.object({
  capacitacion_id: z.number(),
  titulo: z.string(),
  descripcion: z.string().nullable(),
  fecha: z.string().nullable(),
  modalidad: z.string().nullable(),
  tipo: z.string().nullable(),
  estado: z.string().nullable(),
  total_inscritos: z.number(),
});

export const trainingPageSchema = z.object({
  items: z.array(trainingSchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});

export const participantSchema = z.object({
  capacitacion_participante_id: z.number(),
  emprendedor_id: z.number(),
  asistencia: z.boolean().nullable(),
  fecha_registro: z.string().nullable(),
});

export const TRAINING_STATES = ["programada", "realizada", "cancelada"] as const;

export const trainingInputSchema = z.object({
  titulo: z.string().trim().min(1, "Escribe el título.").max(240, "El título es demasiado largo."),
  descripcion: z.string().trim().max(2000, "La descripción es demasiado larga.").optional(),
  day: z.string().optional(),
  time: z.string().optional(),
  modalidad: z.string().trim().max(40).optional(),
  tipo: z.string().trim().max(60).optional(),
  estado: z.enum(TRAINING_STATES).optional(),
});
