"use server";

import { revalidatePath } from "next/cache";
import { headers } from "next/headers";

import { ApiError, apiFetch } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import {
  admittedApplicationSchema,
  applicationFormSchema,
  createdEntrepreneurSchema,
  registerEntrepreneurSchema,
  type ApplicationFormInput,
} from "../schemas/entrepreneurs-schemas";
import type { ApplicationResult, DecisionResult, RegisterResult } from "../types";

/** CU04: registra usuario y emprendedor juntos; el documento de identidad no puede repetirse. */
export async function registerEntrepreneurAction(input: {
  name: string;
  email: string;
  document: string;
}): Promise<RegisterResult> {
  const parsed = registerEntrepreneurSchema.safeParse(input);
  if (!parsed.success) {
    const fieldErrors: Record<string, string> = {};
    for (const issue of parsed.error.issues) {
      const key = String(issue.path[0]);
      if (!(key in fieldErrors)) fieldErrors[key] = issue.message;
    }
    return { ok: false, message: "Revisa los datos marcados.", fieldErrors };
  }
  try {
    const created = createdEntrepreneurSchema.parse(
      await authedFetch("/entrepreneurs", {
        method: "POST",
        body: {
          nombre_completo: parsed.data.name,
          email: parsed.data.email,
          documento_identidad: parsed.data.document,
        },
      }),
    );
    revalidatePath("/entrepreneurs");
    return {
      ok: true,
      message: `Emprendedor registrado: ${created.nombre ?? ""} ${created.apellido ?? ""}.`.replace("  ", " "),
      temporaryPassword: created.temporary_password,
    };
  } catch (error) {
    if (error instanceof ApiError) {
      if (error.code === "document_already_registered")
        return { ok: false, message: "Ese documento ya está registrado.", fieldErrors: { document: "Ya existe un emprendedor con ese documento." } };
      if (error.code === "email_taken")
        return { ok: false, message: "Ese correo ya tiene cuenta.", fieldErrors: { email: "Ya existe una cuenta con ese correo." } };
      if (error.code === "invalid_name")
        return { ok: false, message: "Ingresa nombre y apellido.", fieldErrors: { name: "Ingresa nombre y apellido." } };
      if (error.status === 403) return { ok: false, message: "No tienes permiso para registrar emprendedores." };
    }
    return { ok: false, message: "No se pudo registrar al emprendedor. Intenta de nuevo." };
  }
}

/**
 * Formulario público de postulación (sin sesión). Se reenvía la IP real a la API: sin eso vería siempre
 * la del servidor web y el límite de intentos se compartiría entre todos los postulantes.
 */
export async function submitApplicationAction(input: ApplicationFormInput): Promise<ApplicationResult> {
  const parsed = applicationFormSchema.safeParse(input);
  if (!parsed.success) {
    const fieldErrors: Record<string, string> = {};
    for (const issue of parsed.error.issues) {
      const key = String(issue.path[0]);
      if (!(key in fieldErrors)) fieldErrors[key] = issue.message;
    }
    return { ok: false, message: "Revisa los datos marcados.", fieldErrors };
  }
  const incoming = await headers();
  const ip = incoming.get("x-forwarded-for")?.split(",")[0]?.trim() || incoming.get("x-real-ip") || "";
  try {
    await apiFetch("/applications", {
      method: "POST",
      body: {
        ...parsed.data,
        telefono: parsed.data.telefono || null,
        documento_identidad: parsed.data.documento_identidad || null,
        descripcion_emprendimiento: parsed.data.descripcion_emprendimiento || null,
        sector: parsed.data.sector || null,
      },
      headers: ip ? { "X-Forwarded-For": ip } : {},
    });
  } catch (error) {
    if (error instanceof ApiError) {
      if (error.code === "application_pending")
        return { ok: false, message: "Ya recibimos una postulación con ese correo. La coordinación la está revisando." };
      if (error.status === 429)
        return { ok: false, message: "Enviaste varias postulaciones seguidas. Intenta de nuevo más tarde." };
      if (error.status === 422) return { ok: false, message: "Revisa los datos: alguno no es válido." };
    }
    return { ok: false, message: "No pudimos enviar tu postulación. Intenta de nuevo en unos minutos." };
  }
  return { ok: true, message: "¡Recibimos tu postulación!" };
}

function decisionMessage(error: unknown, fallback: string): string {
  if (error instanceof ApiError) {
    switch (error.code) {
      case "application_decided":
        return "Esta postulación ya fue decidida y no se puede cambiar.";
      case "email_taken":
        return "Ya existe una cuenta con ese correo. No se admitió; revisa si es la misma persona.";
      case "document_already_registered":
        return "Ya hay un emprendedor con ese documento de identidad. No se admitió.";
    }
    if (error.status === 403) return "No tienes permiso para decidir postulaciones.";
  }
  return fallback;
}

/** CU26: admite en una sola transacción (usuario, emprendedor y emprendimiento). La clave temporal se ve una vez. */
export async function admitApplicationAction(id: number, observaciones: string): Promise<DecisionResult> {
  try {
    const admitted = admittedApplicationSchema.parse(
      await authedFetch(`/applications/${id}/admit`, { method: "POST", body: { observaciones: observaciones.trim() || null } }),
    );
    revalidatePath("/admissions");
    revalidatePath("/entrepreneurs");
    revalidatePath("/ventures");
    return {
      ok: true,
      message: `Postulación admitida: ${admitted.nombre} ${admitted.apellido}.`,
      temporaryPassword: admitted.temporary_password,
    };
  } catch (error) {
    revalidatePath("/admissions");
    return { ok: false, message: decisionMessage(error, "No se pudo admitir la postulación. Intenta de nuevo.") };
  }
}

/** CU26: rechaza guardando la observación; la decisión no se puede cambiar después. */
export async function rejectApplicationAction(id: number, observaciones: string): Promise<DecisionResult> {
  if (!observaciones.trim()) return { ok: false, message: "Escribe el motivo del rechazo." };
  try {
    await authedFetch(`/applications/${id}/reject`, { method: "POST", body: { observaciones: observaciones.trim() } });
  } catch (error) {
    revalidatePath("/admissions");
    return { ok: false, message: decisionMessage(error, "No se pudo rechazar la postulación. Intenta de nuevo.") };
  }
  revalidatePath("/admissions");
  return { ok: true, message: "Postulación rechazada." };
}
