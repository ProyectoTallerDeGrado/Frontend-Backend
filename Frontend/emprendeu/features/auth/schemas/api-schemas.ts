import { z } from "zod";

/** Respuestas de `/auth/*` según el OpenAPI del backend. */
export const apiUserSchema = z.object({
  usuario_id: z.number(),
  nombre: z.string(),
  apellido: z.string(),
  email: z.string(),
  telefono: z.string().nullable(),
  estado: z.string().nullable(),
  rol: z.string().nullable(),
  ultimo_acceso: z.string().nullable(),
  fecha_registro: z.string().nullable(),
  /** Cuándo terminó o saltó el tutorial guiado; `null` = se le muestra al entrar. */
  tutorial_completado_at: z.string().nullable().default(null),
  permisos: z.array(z.string()).default([]),
});

export const loginResponseSchema = z.object({
  access_token: z.string(),
  token_type: z.literal("bearer"),
  expires_in: z.number(),
  user: apiUserSchema,
});

export const registeredUserSchema = apiUserSchema.omit({ permisos: true });
