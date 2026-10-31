"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import { createdUserSchema, newUserSchema } from "../schemas/users-schemas";
import type { ActionResult, NewUserState, PermissionMatrix } from "../types";

function fail(error: unknown): ActionResult {
  if (error instanceof ApiError) {
    const message =
      error.code === "cannot_disable_self"
        ? "No puedes deshabilitar tu propia cuenta."
        : error.code === "admin_lockout"
          ? "El rol administrador no puede perder el permiso de administración de usuarios."
          : error.status === 403
            ? "No tienes permiso para esta acción."
            : error.status >= 500 || error.status === 0
              ? "No se pudo completar la acción. Intenta de nuevo."
              : error.message;
    return { ok: false, message };
  }
  return { ok: false, message: "Ocurrió un error inesperado." };
}

export async function setUserStatusAction(
  userId: number,
  estado: "habilitada" | "deshabilitada",
  name: string,
): Promise<ActionResult> {
  try {
    await authedFetch(`/users/${userId}/estado`, { method: "PATCH", body: { estado } });
  } catch (error) {
    return fail(error);
  }
  revalidatePath("/users");
  return {
    ok: true,
    message: `${estado === "habilitada" ? "Cuenta habilitada" : "Cuenta deshabilitada"}: ${name}. Registrado en auditoría.`,
  };
}

export async function changeUserRoleAction(
  userId: number,
  rol: string,
  name: string,
): Promise<ActionResult> {
  try {
    await authedFetch(`/users/${userId}/rol`, { method: "PATCH", body: { rol } });
  } catch (error) {
    return fail(error);
  }
  revalidatePath("/users");
  revalidatePath("/roles");
  return { ok: true, message: `Rol actualizado: ${name}. Registrado en auditoría.` };
}

export async function savePermissionsAction(
  roleId: number,
  roleName: string,
  permisos: PermissionMatrix,
): Promise<ActionResult> {
  try {
    await authedFetch(`/roles/${roleId}/permissions`, { method: "PUT", body: { permisos } });
  } catch (error) {
    return fail(error);
  }
  revalidatePath("/roles");
  return { ok: true, message: `Permisos de ${roleName} guardados. Se aplicarán en el siguiente acceso.` };
}

export async function createUserAction(_prev: NewUserState, formData: FormData): Promise<NewUserState> {
  const raw = {
    name: String(formData.get("name") ?? ""),
    email: String(formData.get("email") ?? ""),
    role: String(formData.get("role") ?? ""),
  };
  const parsed = newUserSchema.safeParse(raw);
  if (!parsed.success) {
    const errors: Record<string, string> = {};
    for (const issue of parsed.error.issues) {
      const key = String(issue.path[0]);
      if (!(key in errors)) errors[key] = issue.message;
    }
    return { errors, values: raw };
  }
  try {
    const created = createdUserSchema.parse(
      await authedFetch("/users", {
        method: "POST",
        body: { nombre_completo: parsed.data.name, email: parsed.data.email, rol: parsed.data.role },
      }),
    );
    revalidatePath("/users");
    return { created: { name: `${created.nombre} ${created.apellido}`, temporaryPassword: created.temporary_password } };
  } catch (error) {
    if (error instanceof ApiError && error.code === "email_taken") {
      return { errors: { email: "Ya existe una cuenta con ese correo." }, values: raw };
    }
    if (error instanceof ApiError && error.code === "invalid_name") {
      return { errors: { name: "Ingresa nombre y apellido." }, values: raw };
    }
    return { message: fail(error).message, values: raw };
  }
}
