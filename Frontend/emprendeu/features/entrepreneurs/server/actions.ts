"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import { createdEntrepreneurSchema, registerEntrepreneurSchema } from "../schemas/entrepreneurs-schemas";
import type { RegisterResult } from "../types";

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
