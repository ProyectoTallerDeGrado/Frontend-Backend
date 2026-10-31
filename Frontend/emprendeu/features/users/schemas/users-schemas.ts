import { z } from "zod";

/** Respuestas de /users y /roles según el OpenAPI del backend. */
export const userSchema = z.object({
  usuario_id: z.number(),
  nombre: z.string(),
  apellido: z.string(),
  email: z.string(),
  telefono: z.string().nullable(),
  estado: z.string().nullable(),
  rol: z.string().nullable(),
  ultimo_acceso: z.string().nullable(),
  fecha_registro: z.string().nullable(),
});

export const userPageSchema = z.object({
  items: z.array(userSchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});

export const createdUserSchema = userSchema.extend({
  temporary_password: z.string().nullable(),
});

export const roleSchema = z.object({
  rol_id: z.number(),
  nombre: z.string(),
  descripcion: z.string().nullable(),
  total_usuarios: z.number(),
});

export const permissionMatrixSchema = z.object({
  permisos: z.record(z.string(), z.array(z.string())),
});

/** Alta de usuario desde el panel (la clave la genera el servidor si se omite). */
export const newUserSchema = z.object({
  name: z
    .string()
    .trim()
    .min(1, "Este campo es obligatorio.")
    .refine((v) => v.split(/\s+/).length >= 2, "Ingresa nombre y apellido."),
  email: z.string().trim().min(1, "Ingresa un correo válido.").pipe(z.email("Ingresa un correo válido.")),
  role: z.string().min(1, "Elige un rol."),
});
