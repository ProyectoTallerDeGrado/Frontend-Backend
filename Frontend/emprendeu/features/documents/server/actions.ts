"use server";

import { revalidatePath } from "next/cache";

import { authedFetch } from "@/features/auth";
import { ApiError } from "@/lib/api-client";

import { validateDocumentFile } from "../schemas/documents-schemas";
import type { ActionResult } from "../types";

function message(error: unknown, fallback: string): string {
  if (error instanceof ApiError) {
    if (error.status === 403) return "No tienes permiso para esta acción.";
    if (error.status === 413) return "El archivo es demasiado grande.";
    if (error.status === 415 || error.code === "file_type_not_allowed") return "Ese tipo de archivo no está permitido.";
    if (error.status < 500 && error.status !== 0) return error.message;
  }
  return fallback;
}

export async function uploadDocumentAction(ventureId: number, formData: FormData): Promise<ActionResult> {
  const file = formData.get("file");
  if (!(file instanceof File)) return { ok: false, message: "Elige un archivo." };
  const problem = validateDocumentFile(file);
  if (problem) return { ok: false, message: problem };
  const body = new FormData();
  body.append("file", file, file.name);
  body.append("emprendimiento_id", String(ventureId));
  try {
    await authedFetch("/documents", { method: "POST", body, timeoutMs: 60_000 });
  } catch (error) {
    return { ok: false, message: message(error, "No se pudo subir el documento. Intenta de nuevo.") };
  }
  revalidatePath(`/ventures/${ventureId}/documents`);
  return { ok: true, message: `Documento subido: ${file.name}.` };
}

export async function deleteDocumentAction(ventureId: number, documentId: number, name: string): Promise<ActionResult> {
  try {
    await authedFetch(`/documents/${documentId}`, { method: "DELETE" });
  } catch (error) {
    return { ok: false, message: message(error, "No se pudo eliminar el documento.") };
  }
  revalidatePath(`/ventures/${ventureId}/documents`);
  return { ok: true, message: `Documento eliminado: ${name}. Registrado en auditoría.` };
}
