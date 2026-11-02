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

export const applicationSchema = z.object({
  postulacion_id: z.number(),
  nombre: z.string(),
  apellido: z.string(),
  email: z.string(),
  telefono: z.string().nullable(),
  documento_identidad: z.string().nullable(),
  nombre_emprendimiento: z.string(),
  descripcion_emprendimiento: z.string().nullable(),
  sector: z.string().nullable(),
  fecha_postulacion: z.string(),
  estado: z.string(),
  fecha_decision: z.string().nullable(),
  observaciones_decision: z.string().nullable(),
  decidido_por: z.string().nullable(),
  emprendedor_id: z.number().nullable(),
  emprendimiento_id: z.number().nullable(),
});

export const applicationPageSchema = z.object({
  items: z.array(applicationSchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});

export const admittedApplicationSchema = applicationSchema.extend({
  temporary_password: z.string().nullable(),
});

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/** Formulario público de postulación; se valida igual en el navegador y en la acción de servidor. */
export const applicationFormSchema = z.object({
  nombre: z.string().trim().min(1, "Escribe tu nombre.").max(160, "Máximo 160 caracteres."),
  apellido: z.string().trim().min(1, "Escribe tu apellido.").max(120, "Máximo 120 caracteres."),
  email: z.string().trim().min(1, "Escribe tu correo.").regex(EMAIL, "Ingresa un correo válido."),
  telefono: z.string().trim().max(35, "Máximo 35 caracteres."),
  documento_identidad: z.string().trim().max(50, "Máximo 50 caracteres."),
  nombre_emprendimiento: z.string().trim().min(1, "Escribe el nombre de tu emprendimiento.").max(160, "Máximo 160 caracteres."),
  descripcion_emprendimiento: z.string().trim().max(2000, "Máximo 2000 caracteres."),
  sector: z.string().trim().max(120, "Máximo 120 caracteres."),
  /** Campo trampa: las personas no lo ven; si viene lleno es un bot. */
  sitio_web: z.string().max(200),
});

export type ApplicationFormInput = z.infer<typeof applicationFormSchema>;
