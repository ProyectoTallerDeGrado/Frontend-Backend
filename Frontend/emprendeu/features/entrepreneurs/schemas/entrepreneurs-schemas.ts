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
