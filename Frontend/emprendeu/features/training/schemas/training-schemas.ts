import { z } from "zod";

export const trainingSchema = z.object({
  capacitacion_id: z.number(),
  titulo: z.string(),
  descripcion: z.string().nullable(),
  fecha: z.string().nullable(),
  modalidad: z.string().nullable(),
  tipo: z.string().nullable(),
  /** `borrador` → `publicada` → `realizada` o `cancelada`. */
  estado: z.string().nullable(),
  total_inscritos: z.number(),
  inscrito: z.boolean().nullable().optional(),
  mi_asistencia: z.boolean().nullable().optional(),
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
  /** `null` = todavía sin registrar. */
  asistencia: z.boolean().nullable(),
  fecha_registro: z.string().nullable(),
  nombre: z.string().nullable(),
  apellido: z.string().nullable(),
  email: z.string().nullable(),
  documento_identidad: z.string().nullable(),
});

export const MODALITIES = ["presencial", "virtual", "híbrida"] as const;

export const trainingFormSchema = z.object({
  titulo: z.string().trim().min(1, "Escribe el título.").max(240, "Máximo 240 caracteres."),
  descripcion: z.string().trim(),
  /** Fecha y hora en Bolivia (`datetime-local`), vacía si aún no se define. */
  fecha: z.string(),
  modalidad: z.string().max(40),
  tipo: z.string().trim().max(60, "Máximo 60 caracteres."),
});

export type TrainingFormInput = z.infer<typeof trainingFormSchema>;
