import { downloadDocument } from "@/features/documents";

/** Descarga de un documento: usa la sesión de la cookie y reenvía el archivo. */
export async function GET(_request: Request, { params }: { params: Promise<{ docId: string }> }) {
  const docId = Number((await params).docId);
  if (!Number.isInteger(docId) || docId <= 0) return new Response("Documento no válido.", { status: 400 });
  return downloadDocument(docId);
}
