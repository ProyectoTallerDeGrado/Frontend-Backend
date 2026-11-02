import { authedDownload } from "@/features/auth";

/** Descarga un documento con la sesión de quien lo pide (el navegador nunca ve el token). */
export async function GET(_request: Request, { params }: RouteContext<"/documents/[id]/download">) {
  const { id } = await params;
  if (!/^\d+$/.test(id)) return new Response("No encontrado", { status: 404 });
  const upstream = await authedDownload(`/documents/${id}/download`);
  if (!upstream.ok) return new Response("No se pudo descargar el documento.", { status: upstream.status === 403 ? 403 : 404 });
  return new Response(upstream.body, {
    headers: {
      "Content-Type": upstream.headers.get("content-type") ?? "application/octet-stream",
      "Content-Disposition": upstream.headers.get("content-disposition") ?? "attachment",
      "Cache-Control": "private, no-store",
    },
  });
}
