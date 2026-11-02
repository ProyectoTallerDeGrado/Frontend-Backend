import { z } from "zod";

export const MIN_PASSWORD_LENGTH = 8;

export const loginSchema = z.object({
  email: z
    .string()
    .trim()
    .min(1, "Ingresa tu correo electrónico.")
    .pipe(z.email("Ingresa un correo válido.")),
  password: z.string().min(1, "Ingresa tu contraseña."),
});

export const registerSchema = z
  .object({
    name: z.string().trim().min(1, "Este campo es obligatorio."),
    email: z
      .string()
      .trim()
      .min(1, "Ingresa tu correo electrónico.")
      .pipe(z.email("Ingresa un correo válido.")),
    password: z
      .string()
      .min(1, "Crea una contraseña.")
      .min(
        MIN_PASSWORD_LENGTH,
        `Usa al menos ${MIN_PASSWORD_LENGTH} caracteres.`,
      ),
    confirmPassword: z.string().min(1, "Repite tu contraseña."),
  })
  .refine((v) => v.password === v.confirmPassword, {
    path: ["confirmPassword"],
    message: "Las contraseñas no coinciden.",
  });

export const changePasswordSchema = z
  .object({
    currentPassword: z.string().min(1, "Ingresa tu contraseña actual."),
    newPassword: z
      .string()
      .min(1, "Crea una contraseña nueva.")
      .min(MIN_PASSWORD_LENGTH, `Usa al menos ${MIN_PASSWORD_LENGTH} caracteres.`)
      .max(128, "Usa como máximo 128 caracteres."),
    confirmPassword: z.string().min(1, "Repite la contraseña nueva."),
  })
  .refine((v) => v.newPassword === v.confirmPassword, {
    path: ["confirmPassword"],
    message: "Las contraseñas no coinciden.",
  })
  .refine((v) => v.newPassword !== v.currentPassword, {
    path: ["newPassword"],
    message: "La contraseña nueva debe ser distinta de la actual.",
  });

export type LoginInput = z.infer<typeof loginSchema>;
export type RegisterInput = z.infer<typeof registerSchema>;

/** Primer mensaje de error por campo, listo para mostrar en el formulario. */
export function fieldErrors(error: z.ZodError): Record<string, string> {
  const out: Record<string, string> = {};
  for (const issue of error.issues) {
    const key = String(issue.path[0] ?? "");
    if (key && !(key in out)) out[key] = issue.message;
  }
  return out;
}
