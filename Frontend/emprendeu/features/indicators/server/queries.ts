import "server-only";

import { authedDownload, authedFetch } from "@/features/auth";

import { dashboardSchema, healthReportSchema, overviewSchema, reportSchema } from "../schemas/indicators-schemas";
import type { Dashboard, HealthReport, Overview, PeriodFilters, Report, ReportKind } from "../types";

export const PREVIEW_ROWS = 50;

export async function getOverview(): Promise<Overview> {
  return overviewSchema.parse(await authedFetch("/indicators/overview"));
}

function periodParams(filters: PeriodFilters): URLSearchParams {
  const search = new URLSearchParams();
  if (filters.desde) search.set("desde", filters.desde);
  if (filters.hasta) search.set("hasta", filters.hasta);
  if (filters.etapa) search.set("etapa_id", String(filters.etapa));
  return search;
}

/** CU14 · Dashboard ejecutivo (solo lectura) por periodo y etapa. */
export async function getDashboard(filters: PeriodFilters): Promise<Dashboard> {
  return dashboardSchema.parse(await authedFetch(`/indicators/dashboard?${periodParams(filters)}`));
}

/** CU21 · Vista previa del reporte (las primeras filas y el total). */
export async function getReport(kind: ReportKind, filters: PeriodFilters): Promise<Report> {
  const search = periodParams(filters);
  search.set("limit", String(PREVIEW_ROWS));
  return reportSchema.parse(await authedFetch(`/indicators/reports/${kind}?${search}`));
}

/** CU21 · Descarga del CSV completo; reenvía el filtro y usa la sesión de la cookie. */
export async function downloadReportCsv(kind: ReportKind, filters: PeriodFilters): Promise<Response> {
  const upstream = await authedDownload(`/indicators/reports/${kind}/export?${periodParams(filters)}`);
  if (!upstream.ok) return new Response("No se pudo exportar el reporte.", { status: upstream.status });
  return new Response(upstream.body, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="reporte-${kind}.csv"`,
    },
  });
}

/** Puntaje de salud de los emprendimientos activos (el asesor recibe solo los suyos). */
export async function getHealth(etapa?: number): Promise<HealthReport> {
  const search = new URLSearchParams();
  if (etapa) search.set("etapa_id", String(etapa));
  return healthReportSchema.parse(await authedFetch(`/indicators/health?${search}`));
}
