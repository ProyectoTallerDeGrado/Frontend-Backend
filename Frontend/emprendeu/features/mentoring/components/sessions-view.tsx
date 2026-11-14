import Link from "next/link";

import { Pagination } from "@/components/layout/pagination";
import { formatDateTime } from "@/lib/format";

import type { Session, SessionFilters, VentureOption } from "../types";
import { CommitSheet, CompleteSessionSheet, RecommendSheet, RegisterSessionSheet } from "./session-forms";

type Props = {
  sessions: Session[];
  filters: SessionFilters;
  /** Solo la lista paginada de coordinación trae total y página. */
  paging?: { page: number; pageSize: number; total: number };
  ventures: VentureOption[];
  canWrite: boolean;
  basePath: string;
};

const STATES = [
  { value: "", label: "Todas" },
  { value: "programada", label: "Programadas" },
  { value: "realizada", label: "Realizadas" },
  { value: "cancelada", label: "Canceladas" },
];

const STATE_BADGE: Record<string, string> = {
  programada: "bg-blue-50 text-primary",
  realizada: "bg-success-tint text-success-foreground",
  cancelada: "bg-danger-tint text-danger-foreground",
};

function hrefFor(basePath: string, filters: SessionFilters, page?: number): string {
  const search = new URLSearchParams();
  if (filters.estado) search.set("estado", filters.estado);
  if (filters.desde) search.set("desde", filters.desde);
  if (filters.hasta) search.set("hasta", filters.hasta);
  if (page && page > 1) search.set("page", String(page));
  const query = search.toString();
  return query ? `${basePath}?${query}` : basePath;
}

function Filters({ filters, basePath }: { filters: SessionFilters; basePath: string }) {
  const pill = (active: boolean) =>
    `inline-flex min-h-11 items-center rounded-full border-[1.5px] px-4 text-sm font-semibold outline-none transition-all focus-visible:ring-3 focus-visible:ring-primary/30 ${active ? "border-navy-900 bg-navy-900 text-white" : "border-border-strong bg-card text-foreground hover:bg-blue-50"}`;
  const dateInput =
    "h-11 rounded-xl border-[1.5px] border-border-strong bg-card px-3 text-sm outline-none focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15";

  return (
    <div className="mb-5 flex flex-wrap items-end gap-x-6 gap-y-4">
      <div role="group" aria-label="Estado" className="flex flex-wrap gap-2">
        {STATES.map((s) => {
          const active = (filters.estado ?? "") === s.value;
          return (
            <Link
              key={s.value}
              href={hrefFor(basePath, { ...filters, estado: s.value || undefined })}
              aria-current={active ? "true" : undefined}
              className={pill(active)}
            >
              {s.label}
            </Link>
          );
        })}
      </div>
      <form method="get" action={basePath} className="flex flex-wrap items-end gap-3">
        {filters.estado && <input type="hidden" name="estado" value={filters.estado} />}
        <label className="flex flex-col gap-1.5 text-[13px] font-semibold">
          Desde
          <input type="date" name="desde" defaultValue={filters.desde ?? ""} className={dateInput} />
        </label>
        <label className="flex flex-col gap-1.5 text-[13px] font-semibold">
          Hasta
          <input type="date" name="hasta" defaultValue={filters.hasta ?? ""} className={dateInput} />
        </label>
        <button
          type="submit"
          className="h-11 rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
        >
          Filtrar por periodo
        </button>
        {(filters.desde || filters.hasta) && (
          <Link
            href={hrefFor(basePath, { estado: filters.estado })}
            className="inline-flex min-h-11 items-center px-2 text-sm font-semibold text-primary"
          >
            Quitar periodo
          </Link>
        )}
      </form>
    </div>
  );
}

export function SessionsView({ sessions, filters, paging, ventures, canWrite, basePath }: Props) {
  return (
    <>
      <Filters filters={filters} basePath={basePath} />
      {canWrite && ventures.length > 0 && (
        <div className="mb-5">
          <RegisterSessionSheet ventures={ventures} />
        </div>
      )}
      <div className="relative overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[820px] border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
              <th scope="col" className="px-5 py-3.5">Cuándo</th>
              <th scope="col" className="px-5 py-3.5">Emprendimiento</th>
              <th scope="col" className="px-5 py-3.5">Tema</th>
              <th scope="col" className="px-5 py-3.5">Asesor</th>
              <th scope="col" className="px-5 py-3.5">Estado</th>
              <th scope="col" className="px-5 py-3.5">Seguimiento</th>
              {canWrite && <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>}
            </tr>
          </thead>
          <tbody>
            {sessions.length === 0 && (
              <tr>
                <td colSpan={canWrite ? 7 : 6} className="px-5 py-10 text-center text-muted-foreground">
                  No hay sesiones con estos filtros.
                </td>
              </tr>
            )}
            {sessions.map((s) => {
              const state = s.estado ?? "";
              return (
                <tr key={s.sesion_id} className="border-t border-muted transition-colors hover:bg-row-hover align-middle">
                  <td className="px-5 py-3.5 font-semibold whitespace-nowrap">
                    {formatDateTime(s.fecha_realizada ?? s.fecha_programada)}
                  </td>
                  <td className="px-5 py-3.5">{s.emprendimiento ?? `#${s.emprendimiento_id}`}</td>
                  <td className="max-w-[220px] truncate px-5 py-3.5" title={s.tema ?? undefined}>
                    {s.tema ?? "—"}
                    {s.modalidad && <span className="text-muted-foreground"> · {s.modalidad}</span>}
                  </td>
                  <td className="px-5 py-3.5">{s.mentor ?? "—"}</td>
                  <td className="px-5 py-3.5">
                    <span className={`rounded-full px-3 py-1 text-[13px] font-bold ${STATE_BADGE[state] ?? "bg-muted text-muted-foreground"}`}>
                      {state ? state.charAt(0).toUpperCase() + state.slice(1) : "—"}
                    </span>
                  </td>
                  <td className="px-5 py-3.5 whitespace-nowrap text-muted-foreground">
                    {s.total_recomendaciones} recom. · {s.total_compromisos} comp.
                  </td>
                  {canWrite && (
                    <td className="px-5 py-3">
                      {state !== "cancelada" && (
                        <div className="flex flex-wrap justify-end gap-2">
                          {state === "programada" && <CompleteSessionSheet session={s} />}
                          <RecommendSheet session={s} />
                          <CommitSheet session={s} />
                        </div>
                      )}
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      {paging && (
        <Pagination
          page={paging.page}
          pageSize={paging.pageSize}
          total={paging.total}
          hrefFor={(page) => hrefFor(basePath, filters, page)}
        />
      )}
    </>
  );
}
