import Link from "next/link";
import { Download } from "lucide-react";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { listStages } from "@/features/ventures";

import { getReport } from "../server/queries";
import type { PeriodFilters, ReportKind } from "../types";
import { PeriodFiltersForm } from "./period-filters";

const KINDS: { kind: ReportKind; label: string; hint: string }[] = [
  { kind: "resumen", label: "Resumen por emprendimiento", hint: "Etapa, sesiones, compromisos, alertas y último avance." },
  { kind: "sesiones", label: "Sesiones de mentoría", hint: "Una fila por sesión del periodo." },
  { kind: "alertas", label: "Alertas", hint: "Una fila por alerta, con quién la atendió." },
  { kind: "indicadores", label: "Indicadores", hint: "Valores registrados por emprendimiento." },
];

function exportHref(kind: ReportKind, filters: PeriodFilters): string {
  const search = new URLSearchParams({ kind });
  if (filters.desde) search.set("desde", filters.desde);
  if (filters.hasta) search.set("hasta", filters.hasta);
  if (filters.etapa) search.set("etapa", String(filters.etapa));
  return `/reports/export?${search}`;
}

function tabHref(kind: ReportKind, filters: PeriodFilters): string {
  const search = new URLSearchParams({ kind });
  if (filters.desde) search.set("desde", filters.desde);
  if (filters.hasta) search.set("hasta", filters.hasta);
  if (filters.etapa) search.set("etapa", String(filters.etapa));
  return `/reports?${search}`;
}

/** CU21 · Reportes con filtros, vista previa en pantalla y exportación a CSV. */
export async function ReportsScreen({ kind, filters }: { kind: ReportKind; filters: PeriodFilters }) {
  const user = await requireSession();
  if (!hasPermission(user, "reportes:consulta")) return <NoAccess section="Reportes" />;

  const [report, stages] = await Promise.all([getReport(kind, filters), listStages()]);
  const current = KINDS.find((k) => k.kind === kind)!;

  return (
    <>
      <PageHeader
        title="Reportes"
        subtitle="Elige un reporte, filtra por periodo y etapa, revisa la vista previa y descárgalo en CSV."
      />
      <div role="group" aria-label="Reporte" className="mb-5 flex flex-wrap gap-2">
        {KINDS.map((k) => {
          const active = k.kind === kind;
          return (
            <Link
              key={k.kind}
              href={tabHref(k.kind, filters)}
              aria-current={active ? "true" : undefined}
              className={`inline-flex min-h-11 items-center rounded-full border-[1.5px] px-4 text-sm font-semibold outline-none transition-all focus-visible:ring-3 focus-visible:ring-primary/30 ${active ? "border-navy-900 bg-navy-900 text-white" : "border-border-strong bg-card text-foreground hover:bg-blue-50"}`}
            >
              {k.label}
            </Link>
          );
        })}
      </div>
      <PeriodFiltersForm basePath="/reports" filters={filters} stages={stages} hidden={{ kind }} />

      <div className="mb-3 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="font-heading text-lg font-semibold">{report.titulo}</h2>
          <p className="text-[13px] text-muted-foreground">
            {current.hint}{" "}
            {report.truncado
              ? `Vista previa: primeras ${report.filas.length} de ${report.total} filas; el CSV las incluye todas.`
              : `${report.total} fila${report.total === 1 ? "" : "s"}.`}
          </p>
        </div>
        <a
          href={exportHref(kind, filters)}
          className="inline-flex h-11 items-center gap-2 rounded-xl bg-primary px-5 text-sm font-bold text-primary-foreground outline-none hover:bg-primary/90 focus-visible:ring-3 focus-visible:ring-primary/30"
        >
          <Download aria-hidden="true" className="size-4" />
          Exportar CSV
        </a>
      </div>

      <div className="overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[720px] border-collapse text-left text-sm">
          <thead>
            <tr className="bg-[#f4f6fb] text-[12px] font-bold tracking-[.06em] text-muted-foreground uppercase">
              {report.columnas.map((c) => (
                <th key={c.clave} scope="col" className="px-5 py-3.5">
                  {c.etiqueta}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {report.filas.length === 0 && (
              <tr>
                <td colSpan={report.columnas.length} className="px-5 py-10 text-center text-muted-foreground">
                  No hay datos con estos filtros.
                </td>
              </tr>
            )}
            {report.filas.map((row, i) => (
              <tr key={i} className="border-t border-[#eef2fa]">
                {report.columnas.map((c) => (
                  <td key={c.clave} className="px-5 py-3">
                    {row[c.clave] === null || row[c.clave] === "" ? "—" : String(row[c.clave])}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
