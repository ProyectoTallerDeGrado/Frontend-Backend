import type { z } from "zod";

import type { permissionMatrixSchema, roleSchema, userSchema } from "./schemas/users-schemas";

export type User = z.infer<typeof userSchema>;
export type Role = z.infer<typeof roleSchema>;
export type PermissionMatrix = z.infer<typeof permissionMatrixSchema>["permisos"];

export type ActionResult = { ok: boolean; message: string };

export type NewUserState = {
  errors?: Record<string, string>;
  message?: string;
  values?: Record<string, string>;
  /** Contraseña temporal devuelta por el servidor; se muestra una sola vez. */
  created?: { name: string; temporaryPassword: string | null };
};
