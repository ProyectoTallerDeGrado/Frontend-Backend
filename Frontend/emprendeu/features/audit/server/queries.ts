import "server-only";

import { authedDownload, authedFetch } from "@/features/auth";

import { auditPageSchema } from "../schemas/audit-schemas";

export const AUDIT_PAGE_SIZE = 20;

export async function listAudit(params: { categoria?: string; page?: number; pageSize?: number }) {
  const search = new URLSearchParams({
    page: String(params.page ?? 1),
    page_size: String(params.pageSize ?? AUDIT_PAGE_SIZE),
  });
  if (params.categoria) search.set("categoria", params.categoria);
  return auditPageSchema.parse(await authedFetch(`/audit?${search}`));
}

/** CSV de la auditoría tal como lo genera el backend. */
export async function downloadAuditCsv(categoria?: string): Promise<Response> {
  const search = new URLSearchParams();
  if (categoria) search.set("categoria", categoria);
  const upstream = await authedDownload(`/audit/export?${search}`);
  if (!upstream.ok) return new Response("No se pudo exportar la auditoría.", { status: upstream.status });
  return new Response(upstream.body, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": 'attachment; filename="auditoria.csv"',
    },
  });
}
