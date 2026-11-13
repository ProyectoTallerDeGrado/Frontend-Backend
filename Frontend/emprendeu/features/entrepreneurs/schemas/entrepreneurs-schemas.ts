import { z } from "zod";

export const entrepreneurSchema = z.object({
  emprendedor_id: z.number(),
  usuario_id: z.number(),
  nombre: z.string().nullable(),
  apellido: z.string().nullable(),
  email: z.string().nullable(),
  documento_identidad: z.string().nullable(),
  estado: z.string().nullable(),
  fecha_registro: z.string().nullable(),
  emprendimientos: z.array(
    z.object({ emprendimiento_id: z.number(), rol_en_emprendimiento: z.string().nullable() }),
  ),
});

export const entrepreneurPageSchema = z.object({
  items: z.array(entrepreneurSchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});

export const createdEntrepreneurSchema = entrepreneurSchema.extend({
  temporary_password: z.string().nullable(),
});

/** Lo que se valida en el borde antes de llamar al backend (CU04). */
export const registerEntrepreneurSchema = z.object({
  name: z.string().trim().min(1, "Ingresa el nombre completo.").refine((v) => v.split(/\s+/).length >= 2, "Ingresa nombre y apellido."),
  email: z.string().trim().min(1, "Ingresa el correo.").regex(/^[^@\s]+@[^@\s]+\.[^@\s]+$/, "Ingresa un correo válido."),
  document: z.string().trim().min(3, "Ingresa el documento de identidad (mínimo 3 caracteres).").max(50, "Máximo 50 caracteres."),
});

// --- CU26 · Admisión al programa -----------------------------------------------------

export const admissionSchema = z.object({
  postulacion_id: z.number(),
  nombre: z.string(),
  apellido: z.string(),
  email: z.string(),
  telefono: z.string().nullable(),
  documento_identidad: z.string().nullable(),
  nombre_emprendimiento: z.string(),
  descripcion_emprendimiento: z.string().nullable(),
  sector: z.string().nullable(),
  estado: z.enum(["pendiente", "admitida", "rechazada"]),
  fecha_postulacion: z.string(),
  fecha_decision: z.string().nullable(),
  observaciones_decision: z.string().nullable(),
  decidido_por_id: z.number().nullable(),
  emprendedor_id: z.number().nullable(),
  emprendimiento_id: z.number().nullable(),
});

export const admissionPageSchema = z.object({
  items: z.array(admissionSchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});

export const admissionDecidedSchema = admissionSchema.extend({ temporary_password: z.string().nullable() });

const optional = (max: number) => z.string().trim().max(max, `Máximo ${max} caracteres.`);

/** Formulario público de postulación (se valida en el borde; el backend vuelve a validar). */
export const applyInputSchema = z.object({
  nombre: z.string().trim().min(1, "Ingresa tu nombre.").max(160, "Máximo 160 caracteres."),
  apellido: z.string().trim().min(1, "Ingresa tus apellidos.").max(120, "Máximo 120 caracteres."),
  email: z.string().trim().min(1, "Ingresa tu correo.").regex(/^[^@\s]+@[^@\s]+\.[^@\s]+$/, "Ingresa un correo válido."),
  telefono: optional(35),
  documento: z.string().trim().min(3, "Ingresa tu documento de identidad (mínimo 3 caracteres).").max(50, "Máximo 50 caracteres."),
  ventureName: z.string().trim().min(1, "Ingresa el nombre de tu emprendimiento.").max(160, "Máximo 160 caracteres."),
  description: optional(4000),
  sector: optional(120),
});

export const DECISIONS = ["admitida", "rechazada", "pendiente"] as const;
export type Decision = (typeof DECISIONS)[number];
