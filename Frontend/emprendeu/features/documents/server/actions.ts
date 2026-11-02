"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import { validateDocumentFile } from "../schemas/documents-schemas";
import type { ActionResult } from "../types";

/** CU30: sube un archivo a un emprendimiento (el backend valida que la persona tenga acceso). */
export async function uploadDocumentAction(formData: FormData): Promise<ActionResult> {
  const file = formData.get("file");
  const ventureId = Number(formData.get("emprendimiento_id"));
  if (!(file instanceof File)) return { ok: false, message: "Elige un archivo." };
  const problem = validateDocumentFile(file);
  if (problem) return { ok: false, message: problem };
  if (!Number.isInteger(ventureId) || ventureId <= 0) return { ok: false, message: "Elige el emprendimiento." };

  const body = new FormData();
  body.append("file", file, file.name);
  body.append("emprendimiento_id", String(ventureId));
  try {
    await authedFetch("/documents", { method: "POST", body, timeoutMs: 60_000 });
  } catch (error) {
    if (error instanceof ApiError) {
      if (error.code === "file_type_not_allowed") return { ok: false, message: "Ese tipo de archivo no es válido." };
      if (error.status === 413) return { ok: false, message: "El archivo supera el tamaño máximo." };
      if (error.status === 403)
        return { ok: false, message: "No puedes subir documentos a ese emprendimiento (un asesor solo en los que tiene asignados)." };
    }
    return { ok: false, message: "No se pudo subir el documento. Intenta de nuevo." };
  }
  revalidatePath("/documents");
  return { ok: true, message: `Documento subido: ${file.name}.` };
}

export async function deleteDocumentAction(id: number, name: string): Promise<ActionResult> {
  try {
    await authedFetch(`/documents/${id}`, { method: "DELETE" });
  } catch (error) {
    const denied = error instanceof ApiError && error.status === 403;
    return { ok: false, message: denied ? "No tienes permiso para eliminar este documento." : "No se pudo eliminar el documento." };
  }
  revalidatePath("/documents");
  return { ok: true, message: `Documento eliminado: ${name}.` };
}
