import "server-only";

import { authedDownload, authedFetch } from "@/features/auth";

import { documentSchema } from "../schemas/documents-schemas";
import type { VentureDocument } from "../types";

/** CU30 · Documentos de un emprendimiento (el backend aplica los permisos). */
export async function listVentureDocuments(ventureId: number): Promise<VentureDocument[]> {
  return documentSchema.array().parse(await authedFetch(`/documents?emprendimiento_id=${ventureId}`));
}

/** Reenvía el archivo del backend con la sesión de la cookie. */
export async function downloadDocument(documentId: number): Promise<Response> {
  const upstream = await authedDownload(`/documents/${documentId}/download`);
  if (!upstream.ok) return new Response("No se pudo descargar el documento.", { status: upstream.status });
  return new Response(upstream.body, {
    headers: {
      "Content-Type": upstream.headers.get("Content-Type") ?? "application/octet-stream",
      "Content-Disposition": upstream.headers.get("Content-Disposition") ?? 'attachment; filename="documento"',
    },
  });
}
