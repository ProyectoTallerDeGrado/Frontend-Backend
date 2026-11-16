import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { Pagination } from "@/components/layout/pagination";
import { hasPermission, requireSession } from "@/features/auth";
import { formatWhen } from "@/lib/format";

import { ALERTS_PAGE_SIZE, listAlerts } from "../server/queries";
import type { AlertFilters } from "../types";
import { AlertActions } from "./alert-actions";
import { filterPillClass } from "@/components/data/filter-pills";

const STATES = [
  { value: "", label: "Todas" },
  { value: "abierta", label: "Abiertas" },
  { value: "revisada", label: "Revisadas" },
  { value: "atendida", label: "Atendidas" },
  { value: "descartada", label: "Descartadas" },
];
const TYPES = [
  { value: "", label: "Todos los tipos" },
  { value: "inactividad", label: "Inactividad" },
  { value: "sentimiento", label: "Sentimiento" },
  { value: "compromiso_vencido", label: "Compromisos vencidos" },
];
const TYPE_LABEL: Record<string, string> = Object.fromEntries(TYPES.map((t) => [t.value, t.label]));

const STATE_BADGE: Record<string, string> = {
  abierta: "bg-danger-tint text-danger-foreground",
  revisada: "bg-warning-tint text-warning-foreground",
  atendida: "bg-success-tint text-success-foreground",
  descartada: "bg-muted text-muted-foreground",
};
const PRIORITY_BADGE: Record<string, string> = {
  alta: "bg-danger-tint text-danger-foreground",
  media: "bg-warning-tint text-warning-foreground",
  baja: "bg-blue-50 text-primary",
};

function href(filters: AlertFilters, page?: number): string {
  const search = new URLSearchParams();
  if (filters.estado) search.set("estado", filters.estado);
  if (filters.tipo) search.set("tipo", filters.tipo);
  if (page && page > 1) search.set("page", String(page));
  const query = search.toString();
  return query ? `/alerts?${query}` : "/alerts";
}

/** CU13 · Bandeja de alertas de seguimiento para coordinación y asesores. */
export async function AlertsScreen({ filters }: { filters: AlertFilters }) {
  const user = await requireSession();
  if (!hasPermission(user, "seguimiento:consulta")) return <NoAccess section="Alertas" />;

  const result = await listAlerts(filters);
  const canManage = hasPermission(user, "seguimiento:registro");
  const subtitle =
    user.rol === "asesor"
      ? "Alertas de los emprendimientos que tienes asignados. Una alerta no cambia el estado del emprendimiento."
      : "Riesgos detectados en los emprendimientos. Una alerta no cambia el estado del emprendimiento.";

  return (
    <>
      <PageHeader title="Alertas" subtitle={subtitle} />
      <div className="mb-5 flex flex-col gap-3">
        <div role="group" aria-label="Estado" className="flex flex-wrap gap-2">
          {STATES.map((s) => {
            const active = (filters.estado ?? "") === s.value;
            return (
              <Link
                key={s.value}
                href={href({ ...filters, estado: s.value || undefined, page: 1 })}
                aria-current={active ? "true" : undefined}
                className={filterPillClass(active)}
              >
                {s.label}
              </Link>
            );
          })}
        </div>
        <div role="group" aria-label="Tipo" className="flex flex-wrap gap-2">
          {TYPES.map((t) => {
            const active = (filters.tipo ?? "") === t.value;
            return (
              <Link
                key={t.value}
                href={href({ ...filters, tipo: t.value || undefined, page: 1 })}
                aria-current={active ? "true" : undefined}
                className={filterPillClass(active)}
              >
                {t.label}
              </Link>
            );
          })}
        </div>
      </div>

      <div className="relative overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[860px] border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
              <th scope="col" className="px-5 py-3.5">Detectada</th>
              <th scope="col" className="px-5 py-3.5">Emprendimiento</th>
              <th scope="col" className="px-5 py-3.5">Alerta</th>
              <th scope="col" className="px-5 py-3.5">Prioridad</th>
              <th scope="col" className="px-5 py-3.5">Estado</th>
              {canManage && <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>}
            </tr>
          </thead>
          <tbody>
            {result.items.length === 0 && (
              <tr>
                <td colSpan={canManage ? 6 : 5} className="px-5 py-10 text-center text-muted-foreground">
                  No hay alertas con estos filtros.
                </td>
              </tr>
            )}
            {result.items.map((a) => {
              const state = a.estado ?? "";
              const unresolved = state === "abierta" || state === "revisada";
              return (
                <tr key={a.alerta_id} className="border-t border-muted transition-colors hover:bg-row-hover align-top">
                  <td className="px-5 py-3.5 whitespace-nowrap text-muted-foreground">{formatWhen(a.fecha_generacion)}</td>
                  <td className="px-5 py-3.5 font-semibold">{a.emprendimiento ?? `#${a.emprendimiento_id}`}</td>
                  <td className="max-w-[340px] px-5 py-3.5">
                    <Link href={`/alerts/${a.alerta_id}`} className="font-semibold text-primary hover:underline">
                      {a.titulo}
                    </Link>
                    <div className="text-[13px] text-muted-foreground">
                      {TYPE_LABEL[a.tipo ?? ""] ?? a.tipo}
                      {a.descripcion ? ` · ${a.descripcion}` : ""}
                    </div>
                  </td>
                  <td className="px-5 py-3.5">
                    <span className={`rounded-full px-3 py-1 text-[13px] font-bold ${PRIORITY_BADGE[a.prioridad ?? ""] ?? "bg-muted text-muted-foreground"}`}>
                      {a.prioridad ? a.prioridad.charAt(0).toUpperCase() + a.prioridad.slice(1) : "—"}
                    </span>
                  </td>
                  <td className="px-5 py-3.5">
                    <span className={`rounded-full px-3 py-1 text-[13px] font-bold ${STATE_BADGE[state] ?? "bg-muted text-muted-foreground"}`}>
                      {state ? state.charAt(0).toUpperCase() + state.slice(1) : "—"}
                    </span>
                    {a.atendida_por && <div className="mt-1 text-[12px] text-muted-foreground">por {a.atendida_por}</div>}
                  </td>
                  {canManage && <td className="px-5 py-3">{unresolved && <AlertActions alert={a} />}</td>}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <Pagination
        page={result.page}
        pageSize={ALERTS_PAGE_SIZE}
        total={result.total}
        hrefFor={(p) => href(filters, p)}
      />
    </>
  );
}
