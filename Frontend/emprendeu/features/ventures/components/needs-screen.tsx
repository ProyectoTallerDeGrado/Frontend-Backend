import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { Pagination } from "@/components/layout/pagination";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { NEEDS_PAGE_SIZE, listNeeds } from "../server/queries";
import type { NeedFilters } from "../types";
import { ResolveNeedButton } from "./resolve-need-button";
import { filterPillClass } from "@/components/data/filter-pills";

const ESTADOS = [
  { value: "", label: "Todas" },
  { value: "detectada", label: "Abiertas" },
  { value: "resuelta", label: "Resueltas" },
] as const;
const TIPOS = [
  { value: "", label: "Todos los tipos" },
  { value: "necesidad", label: "Necesidades" },
  { value: "dificultad", label: "Dificultades" },
] as const;
const PRIORITY: Record<string, string> = { alta: "bg-danger-tint text-danger-foreground", media: "bg-warning-tint text-warning-foreground", baja: "bg-blue-50 text-primary" };

function hrefFor(f: NeedFilters): string {
  const search = new URLSearchParams();
  if (f.estado) search.set("estado", f.estado);
  if (f.tipo) search.set("tipo", f.tipo);
  if (f.page && f.page > 1) search.set("page", String(f.page));
  const query = search.toString();
  return query ? `/needs?${query}` : "/needs";
}

/** CU24 · Bandeja del personal: necesidades y dificultades que reportan los emprendedores. */
export async function NeedsScreen({ filters }: { filters: NeedFilters }) {
  const user = await requireSession();
  if (!hasPermission(user, "seguimiento:consulta")) return <NoAccess section="Necesidades" />;

  const result = await listNeeds(filters);
  const canResolve = hasPermission(user, "seguimiento:modificacion");

  return (
    <>
      <PageHeader
        title="Necesidades y dificultades"
        subtitle="Lo que reportan los emprendedores para que el CIE-U lo atienda. Las abiertas aparecen primero."
      />
      <div className="mb-3 flex flex-wrap gap-2" role="group" aria-label="Filtrar por estado">
        {ESTADOS.map((e) => (
          <Link
            key={e.value}
            href={hrefFor({ ...filters, estado: e.value ? (e.value as NeedFilters["estado"]) : undefined, page: 1 })}
            aria-current={(filters.estado ?? "") === e.value ? "true" : undefined}
            className={filterPillClass((filters.estado ?? "") === e.value)}
          >
            {e.label}
          </Link>
        ))}
      </div>
      <div className="mb-5 flex flex-wrap gap-2" role="group" aria-label="Filtrar por tipo">
        {TIPOS.map((t) => (
          <Link
            key={t.value}
            href={hrefFor({ ...filters, tipo: t.value ? (t.value as NeedFilters["tipo"]) : undefined, page: 1 })}
            aria-current={(filters.tipo ?? "") === t.value ? "true" : undefined}
            className={filterPillClass((filters.tipo ?? "") === t.value)}
          >
            {t.label}
          </Link>
        ))}
      </div>

      <div className="relative overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[920px] border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
              <th scope="col" className="px-5 py-3.5">Emprendimiento</th>
              <th scope="col" className="px-5 py-3.5">Reporte</th>
              <th scope="col" className="px-5 py-3.5">Prioridad</th>
              <th scope="col" className="px-5 py-3.5">Detectada</th>
              <th scope="col" className="px-5 py-3.5">Estado</th>
              <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>
            </tr>
          </thead>
          <tbody>
            {result.items.length === 0 && (
              <tr>
                <td colSpan={6} className="px-5 py-10 text-center text-muted-foreground">
                  No hay reportes con ese criterio.
                </td>
              </tr>
            )}
            {result.items.map((n) => (
              <tr key={n.emprendimiento_necesidad_id} className="border-t border-muted transition-colors hover:bg-row-hover align-top">
                <td className="px-5 py-3.5">
                  <Link href={`/ventures/${n.emprendimiento_id}/history`} className="font-semibold text-primary hover:underline">
                    {n.emprendimiento}
                  </Link>
                </td>
                <td className="px-5 py-3.5">
                  <div className="text-[13px] font-semibold text-muted-foreground">
                    {n.tipo === "dificultad" ? "Dificultad" : "Necesidad"}
                  </div>
                  <div className="font-semibold">{n.necesidad}</div>
                  {n.descripcion && <p className="mt-1 max-w-[420px] text-[13px] leading-snug text-muted-foreground">{n.descripcion}</p>}
                </td>
                <td className="px-5 py-3.5">
                  <span className={`rounded-full px-3 py-1 text-[13px] font-bold capitalize ${PRIORITY[n.prioridad ?? ""] ?? "bg-muted"}`}>
                    {n.prioridad ?? "—"}
                  </span>
                </td>
                <td className="px-5 py-3.5 text-muted-foreground">{n.fecha_detectada ? formatDateTime(n.fecha_detectada) : "—"}</td>
                <td className="px-5 py-3.5">
                  {n.estado === "resuelta" ? (
                    <span className="font-semibold text-success-foreground">
                      Resuelta{n.fecha_resuelta ? ` · ${formatDateTime(n.fecha_resuelta)}` : ""}
                    </span>
                  ) : (
                    <span className="font-semibold">Abierta</span>
                  )}
                </td>
                <td className="px-5 py-3 text-right">
                  {canResolve && n.estado !== "resuelta" && (
                    <ResolveNeedButton rowId={n.emprendimiento_necesidad_id} name={n.necesidad} />
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination page={result.page} pageSize={NEEDS_PAGE_SIZE} total={result.total} hrefFor={(p) => hrefFor({ ...filters, page: p })} />
    </>
  );
}
