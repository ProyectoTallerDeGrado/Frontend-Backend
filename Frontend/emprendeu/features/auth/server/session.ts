import "server-only";

import { cache } from "react";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { ApiError, apiFetch } from "@/lib/api-client";
import { env } from "@/lib/env";

import { apiUserSchema } from "../schemas/api-schemas";
import { MOBILE_ONLY_ROLE, type SessionUser } from "../types";

export const SESSION_COOKIE = "emprendeu_session";

export async function setSessionToken(token: string, expiresInSeconds: number) {
  const store = await cookies();
  store.set(SESSION_COOKIE, token, {
    httpOnly: true,
    sameSite: "lax",
    secure: env.isProduction,
    path: "/",
    maxAge: expiresInSeconds,
  });
}

export async function clearSessionToken() {
  const store = await cookies();
  store.delete(SESSION_COOKIE);
}

export async function getSessionToken(): Promise<string | undefined> {
  return (await cookies()).get(SESSION_COOKIE)?.value;
}

/** Usuario de la sesión actual o `null` (sin cookie, token vencido o cuenta sin acceso al panel). */
export const getSession = cache(async (): Promise<SessionUser | null> => {
  const token = await getSessionToken();
  if (!token) return null;
  try {
    const user = apiUserSchema.parse(await apiFetch("/auth/me", { token }));
    if (user.estado === "deshabilitada" || user.rol === MOBILE_ONLY_ROLE) return null;
    return user;
  } catch (error) {
    if (error instanceof ApiError && error.status >= 500) throw error;
    return null;
  }
});

/** Exige sesión en una página o layout; si no hay, manda a /login. */
export async function requireSession(): Promise<SessionUser> {
  const user = await getSession();
  if (!user) redirect("/login");
  return user;
}
