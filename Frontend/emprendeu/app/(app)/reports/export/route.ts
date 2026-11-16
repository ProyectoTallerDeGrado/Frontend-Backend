import type { NextRequest } from "next/server";

import { REPORT_KINDS, downloadReport, type ReportKind } from "@/features/indicators";

const DAY = /^\d{4}-\d{2}-\d{2}$/;

/** Descarga de un reporte en CSV o Excel: reenvía el filtro y usa la sesión de la cookie. */
export async function GET(request: NextRequest) {
  const params = request.nextUrl.searchParams;
  const kind = params.get("kind") ?? "";
  if (!(REPORT_KINDS as readonly string[]).includes(kind)) {
    return new Response("Tipo de reporte no válido.", { status: 400 });
  }
  const desde = params.get("desde") ?? "";
  const hasta = params.get("hasta") ?? "";
  return downloadReport(
    kind as ReportKind,
    {
      desde: DAY.test(desde) ? desde : undefined,
      hasta: DAY.test(hasta) ? hasta : undefined,
      etapa: Number(params.get("etapa")) || undefined,
    },
    params.get("formato") === "xlsx" ? "xlsx" : "csv",
  );
}
