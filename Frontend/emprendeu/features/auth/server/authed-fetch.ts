import "server-only";

import { redirect } from "next/navigation";

import { ApiError, apiFetch } from "@/lib/api-client";

import type { SessionUser } from "../types";
import { getSessionToken } from "./session";

type Options = { method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE"; body?: unknown; timeoutMs?: number };

/** Llama al backend con el token de la sesión. Sin sesión o token vencido manda a /login. */
export async function authedFetch(path: string, options: Options = {}): Promise<unknown> {
  const token = await getSessionToken();
  if (!token) redirect("/login");
  try {
    return await apiFetch(path, { ...options, token });
  } catch (error) {
    if (error instanceof ApiError && error.status === 401) redirect("/login");
    throw error;
  }
}

/** Igual que `authedFetch` pero para descargas (devuelve la respuesta cruda). */
export async function authedDownload(path: string): Promise<Response> {
  const token = await getSessionToken();
  if (!token) redirect("/login");
  const { env } = await import("@/lib/env");
  return fetch(`${env.apiUrl}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: "no-store",
  });
}

export function hasPermission(user: SessionUser, permission: string): boolean {
  return user.permisos.includes(permission);
}
