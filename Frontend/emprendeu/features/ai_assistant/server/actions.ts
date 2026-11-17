"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import { HELP_HISTORY_MAX, HELP_MESSAGE_MAX, helpReplySchema, validateKnowledgeFile } from "../schemas/ai-schemas";
import type { ActionResult, HelpMessage, HelpResult } from "../types";

function uploadMessage(error: unknown): string {
  if (error instanceof ApiError) {
    switch (error.code) {
      case "file_type_not_allowed":
        return "Ese tipo de archivo no es válido. Usa .txt, .md, .pdf o .docx.";
      case "file_unreadable":
        return "No se pudo leer el texto del archivo. ¿Está dañado?";
      case "empty_knowledge":
        return "El archivo no tiene texto que se pueda indexar (¿es un PDF escaneado?).";
      case "payload_too_large":
        return "El archivo supera el tamaño máximo permitido.";
      case "ai_unavailable":
        return "El servicio de IA no responde. El documento quedó en estado «Error»; vuelve a subirlo cuando el servicio esté disponible.";
    }
    if (error.status === 403) return "No tienes permiso para administrar la base de conocimiento.";
  }
  return "No se pudo subir el documento. Intenta de nuevo.";
}

/**
 * CU31: sube un documento. El backend lo guarda como «procesando», lo trocea, calcula los
 * embeddings y lo deja «activo» (o «error» si el servicio de IA no responde).
 */
export async function uploadKnowledgeAction(formData: FormData): Promise<ActionResult> {
  const file = formData.get("file");
  const title = String(formData.get("titulo") ?? "").trim();
  if (!(file instanceof File)) return { ok: false, message: "Elige un archivo." };
  const problem = validateKnowledgeFile(file);
  if (problem) return { ok: false, message: problem };
  if (!title) return { ok: false, message: "Escribe un título para el documento." };

  const body = new FormData();
  body.append("file", file, file.name);
  body.append("titulo", title);
  const description = String(formData.get("descripcion") ?? "").trim();
  const source = String(formData.get("fuente") ?? "").trim();
  if (description) body.append("descripcion", description);
  if (source) body.append("fuente", source);

  try {
    // Calcular los embeddings puede tardar: plazo largo.
    await authedFetch("/ai/knowledge/upload", { method: "POST", body, timeoutMs: 120_000 });
  } catch (error) {
    // Si el servicio de IA cayó, el intento quedó registrado en estado «error».
    if (error instanceof ApiError && error.code === "ai_unavailable") revalidatePath("/knowledge");
    return { ok: false, message: uploadMessage(error) };
  }
  revalidatePath("/knowledge");
  return { ok: true, message: `Documento cargado: ${title}. Ya lo usa el coach.` };
}

/** Retira un documento de las respuestas del coach (queda en la lista como inactivo). */
export async function deactivateKnowledgeAction(id: number, title: string): Promise<ActionResult> {
  try {
    await authedFetch(`/ai/knowledge/${id}`, { method: "DELETE" });
  } catch (error) {
    const denied = error instanceof ApiError && error.status === 403;
    return { ok: false, message: denied ? "No tienes permiso para esta acción." : "No se pudo desactivar el documento." };
  }
  revalidatePath("/knowledge");
  return { ok: true, message: `Documento desactivado: ${title}. El coach ya no lo usa.` };
}

/**
 * Asistente de ayuda del panel: pregunta cómo usar el sistema. El backend responde con
 * Gemini o, si no hay cuota o falla, con la guía sin IA; nunca guarda la conversación.
 */
export async function askHelpAction(
  message: string,
  history: Pick<HelpMessage, "role" | "text">[],
  route: string,
): Promise<HelpResult> {
  const text = message.trim().slice(0, HELP_MESSAGE_MAX);
  if (!text) return { ok: false, message: "Escribe tu pregunta." };
  try {
    const data = await authedFetch("/ai/help", {
      method: "POST",
      body: {
        mensaje: text,
        ruta: route.slice(0, 200),
        historial: history.slice(-HELP_HISTORY_MAX).map((m) => ({ rol: m.role, texto: m.text.slice(0, 4000) })),
      },
      timeoutMs: 40_000,
    });
    return { ok: true, reply: helpReplySchema.parse(data) };
  } catch {
    return { ok: false, message: "No pude responder ahora. Revisa tu conexión e intenta de nuevo." };
  }
}
