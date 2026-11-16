"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import { createdUserSchema, newUserSchema, roleSchema } from "../schemas/users-schemas";
import { PERMISSION_MODULES } from "../roles";
import type { ActionResult, NewUserState, PermissionMatrix } from "../types";

function fail(error: unknown): ActionResult {
  if (error instanceof ApiError) {
    const message =
      error.code === "cannot_disable_self"
        ? "No puedes deshabilitar tu propia cuenta."
        : error.code === "admin_lockout"
          ? "El rol administrador debe conservar la consulta y la administración de usuarios."
          : error.code === "role_name_taken"
            ? "Ya existe un rol con ese nombre."
            : error.code === "role_in_use"
              ? "El rol tiene usuarios asignados: reasígnalos antes de eliminarlo."
              : error.code === "system_role_protected"
                ? "Los roles del sistema no se pueden renombrar ni eliminar."
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
  return { ok: true, message: `Permisos de ${roleName} guardados. Los cambios rigen de inmediato.` };
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

export async function createRoleAction(input: {
  nombre: string;
  descripcion: string;
  plantilla: "vacio" | "lectura";
  clonarDe: number | null;
}): Promise<ActionResult> {
  const nombre = input.nombre.trim();
  if (nombre.length < 3) return { ok: false, message: "El nombre debe tener al menos 3 caracteres." };
  try {
    const created = roleSchema.parse(await authedFetch("/roles", {
      method: "POST",
      body: {
        nombre,
        descripcion: input.descripcion.trim() || null,
        clonar_de: input.clonarDe,
      },
    }));
    if (input.plantilla === "lectura" && input.clonarDe === null) {
      const permisos = Object.fromEntries(PERMISSION_MODULES.map((m) => [m.key, ["consulta"]]));
      await authedFetch(`/roles/${created.rol_id}/permissions`, { method: "PUT", body: { permisos } });
    }
  } catch (error) {
    if (error instanceof ApiError && error.status === 422) {
      return { ok: false, message: "Usa solo letras, números, espacios, guiones y guion bajo en el nombre." };
    }
    return fail(error);
  }
  revalidatePath("/roles");
  revalidatePath("/users");
  return { ok: true, message: `Rol creado: ${nombre}. Registrado en auditoría.` };
}

export async function deleteRoleAction(roleId: number, roleName: string): Promise<ActionResult> {
  try {
    await authedFetch(`/roles/${roleId}`, { method: "DELETE" });
  } catch (error) {
    return fail(error);
  }
  revalidatePath("/roles");
  revalidatePath("/users");
  return { ok: true, message: `Rol eliminado: ${roleName}. Registrado en auditoría.` };
}

/** CU03: renombra un rol personalizado o cambia su descripción (los roles del sistema están protegidos). */
export async function editRoleAction(
  roleId: number,
  input: { nombre: string; descripcion: string },
): Promise<ActionResult> {
  const nombre = input.nombre.trim();
  if (nombre.length < 3) return { ok: false, message: "El nombre debe tener al menos 3 caracteres." };
  try {
    await authedFetch(`/roles/${roleId}`, {
      method: "PATCH",
      body: { nombre, descripcion: input.descripcion.trim() || null },
    });
  } catch (error) {
    if (error instanceof ApiError && error.status === 422) {
      return { ok: false, message: "Usa solo letras, números, espacios, guiones y guion bajo en el nombre." };
    }
    return fail(error);
  }
  revalidatePath("/roles");
  revalidatePath("/users");
  return { ok: true, message: `Rol actualizado: ${nombre}. Registrado en auditoría.` };
}
