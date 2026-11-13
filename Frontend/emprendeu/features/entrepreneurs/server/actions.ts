"use server";

import { revalidatePath } from "next/cache";

import { ApiError, apiFetch } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import {
  admissionDecidedSchema,
  applyInputSchema,
  createdEntrepreneurSchema,
  registerEntrepreneurSchema,
  type Decision,
} from "../schemas/entrepreneurs-schemas";
import type { ApplyResult, DecisionResult, RegisterResult } from "../types";

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

/** CU26 · Postulación pública (sin sesión): el backend limita los envíos por IP. */
export async function applyAction(input: Record<string, string>): Promise<ApplyResult> {
  const parsed = applyInputSchema.safeParse(input);
  if (!parsed.success) {
    const fieldErrors: Record<string, string> = {};
    for (const issue of parsed.error.issues) {
      const key = String(issue.path[0]);
      if (!(key in fieldErrors)) fieldErrors[key] = issue.message;
    }
    return { ok: false, message: "Revisa los datos marcados.", fieldErrors };
  }
  const v = parsed.data;
  try {
    await apiFetch("/admissions", {
      method: "POST",
      body: {
        nombre: v.nombre,
        apellido: v.apellido,
        email: v.email,
        telefono: v.telefono || null,
        documento_identidad: v.documento,
        nombre_emprendimiento: v.ventureName,
        descripcion_emprendimiento: v.description || null,
        sector: v.sector || null,
      },
    });
  } catch (error) {
    if (error instanceof ApiError) {
      if (error.code === "application_pending")
        return { ok: false, message: "Ya tenemos una postulación pendiente con ese correo.", fieldErrors: { email: "Ya hay una postulación pendiente con este correo." } };
      if (error.code === "rate_limited" || error.status === 429)
        return { ok: false, message: "Enviaste varias postulaciones seguidas. Intenta de nuevo en un rato." };
      if (error.status === 422) return { ok: false, message: "Revisa los datos del formulario." };
    }
    return { ok: false, message: "No se pudo enviar la postulación. Intenta de nuevo." };
  }
  return { ok: true, message: "Recibimos tu postulación. El equipo del CIE-U la evaluará y se pondrá en contacto contigo." };
}

/** CU26 · Admite, rechaza o deja pendiente una postulación (admitida y rechazada son definitivas). */
export async function decideAdmissionAction(
  id: number,
  decision: Decision,
  observaciones: string,
): Promise<DecisionResult> {
  if (decision === "rechazada" && !observaciones.trim()) {
    return { ok: false, message: "Escribe el motivo del rechazo." };
  }
  try {
    const result = admissionDecidedSchema.parse(
      await authedFetch(`/admissions/${id}/decision`, {
        method: "POST",
        body: { decision, observaciones: observaciones.trim() || null },
      }),
    );
    revalidatePath("/admissions");
    revalidatePath(`/admissions/${id}`);
    revalidatePath("/entrepreneurs");
    const label = { admitida: "admitida", rechazada: "rechazada", pendiente: "mantenida como pendiente" }[decision];
    return { ok: true, message: `Postulación ${label}. Registrado en auditoría.`, temporaryPassword: result.temporary_password };
  } catch (error) {
    if (error instanceof ApiError) {
      if (error.code === "decision_final") return { ok: false, message: "Esta postulación ya tiene una decisión definitiva." };
      if (error.code === "admission_incomplete") {
        const missing = (error.details as { faltan?: string[] } | null)?.faltan ?? [];
        return { ok: false, message: missing.includes("documento_identidad") ? "Falta el documento de identidad: no se puede admitir." : "Faltan datos para decidir." };
      }
      if (error.code === "email_taken") return { ok: false, message: "Ese correo ya tiene una cuenta: no se puede crear otra." };
      if (error.code === "document_already_registered") return { ok: false, message: "Ese documento ya pertenece a otro emprendedor." };
      if (error.status === 403) return { ok: false, message: "No tienes permiso para decidir admisiones." };
    }
    return { ok: false, message: "No se pudo registrar la decisión. Intenta de nuevo." };
  }
}
