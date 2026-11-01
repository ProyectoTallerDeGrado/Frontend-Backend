import type { z } from "zod";

import type { apiUserSchema } from "./schemas/api-schemas";

/** Usuario autenticado tal como lo entrega `/auth/me`. */
export type SessionUser = z.infer<typeof apiUserSchema>;

/** Estado que devuelven las acciones de formulario (`useActionState`). */
export type FormState = {
  errors?: Record<string, string>;
  message?: string;
  values?: Record<string, string>;
};

/** El panel web es para el personal; los emprendedores usan la app móvil. */
export const MOBILE_ONLY_ROLE = "emprendedor";

export const ROLE_LABELS: Record<string, string> = {
  administrador: "Administrador",
  coordinador: "Coordinador",
  asesor: "Asesor / Mentor",
  emprendedor: "Emprendedor",
};
