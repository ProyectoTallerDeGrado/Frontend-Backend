import { z } from "zod";

/** Respuestas de `/mentoring/*` según el OpenAPI del backend. */
export const mentorSchema = z.object({
  usuario_id: z.number(),
  nombre: z.string(),
  especialidad: z.string().nullable(),
  habilitado: z.boolean(),
  bloqueado: z.boolean(),
  motivo_bloqueo: z.string().nullable(),
});

export const assignmentSchema = z.object({
  asignacion_id: z.number(),
  usuario_id: z.number(),
  usuario: z.string().nullable(),
  emprendimiento_id: z.number(),
  emprendimiento: z.string().nullable(),
  tipo_asignacion: z.string().nullable(),
  estado: z.string().nullable(),
  fecha_inicio: z.string().nullable(),
  fecha_fin: z.string().nullable(),
});

export const availabilitySchema = z.object({
  disponibilidad_id: z.number(),
  fecha_inicio: z.string(),
  fecha_fin: z.string(),
  estado: z.enum(["disponible", "bloqueado", "reservado"]),
});

export const participantSchema = z.object({
  usuario_id: z.number(),
  nombre: z.string().nullable(),
  rol: z.string().nullable(),
});

export const sessionSchema = z.object({
  sesion_id: z.number(),
  emprendimiento_id: z.number(),
  emprendimiento: z.string().nullable(),
  estado: z.string().nullable(),
  tema: z.string().nullable(),
  modalidad: z.string().nullable(),
  fecha_programada: z.string().nullable(),
  fecha_realizada: z.string().nullable(),
  observaciones: z.string().nullable(),
  participantes: z.array(participantSchema),
  mentor: z.string().nullable(),
  total_recomendaciones: z.number(),
  total_compromisos: z.number(),
});

export const sessionPageSchema = z.object({
  items: z.array(sessionSchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});

// --- Entradas de formulario (validación en el borde, antes de llamar al backend) ---

const day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Elige una fecha.");
const time = z.string().regex(/^\d{2}:\d{2}$/, "Elige una hora.");
const modality = z.enum(["presencial", "virtual", "hibrida"], "Elige la modalidad.");

export const availabilityInputSchema = z
  .object({ date: day, start: time, end: time })
  .refine((v) => v.end > v.start, { path: ["end"], message: "La hora de fin debe ser posterior al inicio." });

export const sessionInputSchema = z.object({
  date: day,
  time,
  tema: z.string().trim().min(1, "Escribe el tema.").max(250, "Máximo 250 caracteres."),
  modalidad: modality,
  observaciones: z.string().trim().max(4000, "Máximo 4000 caracteres."),
});

export const registerSessionInputSchema = sessionInputSchema.extend({
  ventureId: z.number("Elige un emprendimiento."),
});

export const recommendationInputSchema = z.object({
  ventureId: z.number(),
  sessionId: z.number().nullable(),
  titulo: z.string().trim().min(1, "Escribe un título.").max(240, "Máximo 240 caracteres."),
  contenido: z.string().trim().min(1, "Escribe la recomendación."),
});

export const commitmentInputSchema = z.object({
  ventureId: z.number(),
  sessionId: z.number().nullable(),
  responsibleId: z.number("Elige quién es responsable."),
  descripcion: z.string().trim().min(1, "Describe el compromiso."),
  dueDate: z.string(), // vacío = el backend usa dias_limite_compromiso
});

export const historyEventSchema = z.object({
  tipo: z.enum(["sesion", "avance", "hito", "recomendacion", "compromiso", "etapa"]),
  referencia_id: z.number(),
  fecha: z.string().nullable(),
  titulo: z.string(),
  detalle: z.string().nullable(),
  estado: z.string().nullable(),
  autor: z.string().nullable(),
});
