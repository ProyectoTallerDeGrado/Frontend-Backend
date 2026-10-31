import type { NextRequest } from "next/server";

import { downloadAuditCsv } from "@/features/audit";

/** Descarga del CSV de auditoría: reenvía el filtro y usa la sesión de la cookie. */
export async function GET(request: NextRequest) {
  const categoria = request.nextUrl.searchParams.get("categoria") ?? undefined;
  return downloadAuditCsv(categoria);
}
