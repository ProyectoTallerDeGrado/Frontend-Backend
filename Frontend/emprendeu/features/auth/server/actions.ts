"use server";

import { redirect } from "next/navigation";

import { ApiError, apiFetch } from "@/lib/api-client";

import {
  fieldErrors,
  loginSchema,
  registerSchema,
} from "../schemas/auth-schemas";
import { loginResponseSchema } from "../schemas/api-schemas";
import { MOBILE_ONLY_ROLE, type FormState } from "../types";
import { clearSessionToken, getSessionToken, setSessionToken } from "./session";

function text(formData: FormData, key: string): string {
  const value = formData.get(key);
  return typeof value === "string" ? value : "";
}

/** Traduce un error del backend a un mensaje para el usuario. */
function messageFor(error: unknown): string {
  if (!(error instanceof ApiError)) return "Ocurrió un error inesperado. Intenta de nuevo.";
  switch (error.code) {
    case "invalid_credentials":
      return "Correo o contraseña incorrectos.";
    case "account_disabled":
      return "Tu cuenta está deshabilitada. Contacta al CIE-U.";
    case "rate_limited": {
      const seconds = Number((error.details as { retry_after?: number } | null)?.retry_after ?? 0);
      const minutes = Math.max(1, Math.ceil(seconds / 60));
      return `Demasiados intentos. Intenta de nuevo en ${minutes} min.`;
    }
    case "network_error":
      return "No se pudo conectar con el servidor. Intenta de nuevo.";
    default:
      return error.status >= 500
        ? "El servidor tuvo un problema. Intenta de nuevo en unos minutos."
        : error.message;
  }
}

export async function loginAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const values = { email: text(formData, "email").trim() };
  const parsed = loginSchema.safeParse({ email: values.email, password: text(formData, "password") });
  if (!parsed.success) return { errors: fieldErrors(parsed.error), values };

  try {
    const session = loginResponseSchema.parse(
      await apiFetch("/auth/login", { method: "POST", body: parsed.data }),
    );
    if (session.user.rol === MOBILE_ONLY_ROLE) {
      return {
        message: "Esta cuenta es de emprendedor: usa la app móvil del CIE-U.",
        values,
      };
    }
    await setSessionToken(session.access_token, session.expires_in);
  } catch (error) {
    return { message: messageFor(error), values };
  }
  redirect("/");
}

export async function registerAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const values = { name: text(formData, "name").trim(), email: text(formData, "email").trim() };
  const parsed = registerSchema.safeParse({
    ...values,
    password: text(formData, "password"),
    confirmPassword: text(formData, "confirmPassword"),
  });
  if (!parsed.success) return { errors: fieldErrors(parsed.error), values };

  try {
    await apiFetch("/auth/register", {
      method: "POST",
      body: {
        nombre_completo: parsed.data.name,
        email: parsed.data.email,
        password: parsed.data.password,
      },
    });
  } catch (error) {
    if (error instanceof ApiError && error.code === "email_taken") {
      return { errors: { email: "Ya existe una cuenta con ese correo." }, values };
    }
    if (error instanceof ApiError && error.code === "invalid_name") {
      return { errors: { name: "Ingresa nombre y apellido." }, values };
    }
    return { message: messageFor(error), values };
  }
  redirect("/login?registrado=1");
}

export async function logoutAction(): Promise<void> {
  // El token es un JWT sin estado en el servidor: basta con descartarlo.
  if (await getSessionToken()) await clearSessionToken();
  redirect("/login");
}
