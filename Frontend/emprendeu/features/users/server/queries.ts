import "server-only";

import { authedFetch } from "@/features/auth";

import {
  permissionMatrixSchema,
  roleSchema,
  userPageSchema,
} from "../schemas/users-schemas";
import type { PermissionMatrix, Role } from "../types";

export const USERS_PAGE_SIZE = 20;

export async function listUsers(params: { q?: string; rol?: string; page?: number }) {
  const search = new URLSearchParams({
    page: String(params.page ?? 1),
    page_size: String(USERS_PAGE_SIZE),
  });
  if (params.q) search.set("q", params.q);
  if (params.rol) search.set("rol", params.rol);
  return userPageSchema.parse(await authedFetch(`/users?${search}`));
}

export async function listRoles(): Promise<Role[]> {
  return roleSchema.array().parse(await authedFetch("/roles"));
}

/** Matriz de permisos de cada rol, indexada por `rol_id`. */
export async function getRoleMatrices(roles: Role[]): Promise<Record<number, PermissionMatrix>> {
  const entries = await Promise.all(
    roles.map(async (r) => {
      const data = permissionMatrixSchema.parse(await authedFetch(`/roles/${r.rol_id}/permissions`));
      return [r.rol_id, data.permisos] as const;
    }),
  );
  return Object.fromEntries(entries);
}
