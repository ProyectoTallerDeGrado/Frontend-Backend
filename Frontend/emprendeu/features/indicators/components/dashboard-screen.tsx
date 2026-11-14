import { CountUp } from "@/components/data/count-up";
import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { listStages } from "@/features/ventures";

import { getDashboard } from "../server/queries";
import type { PeriodFilters } from "../types";
import { PeriodFiltersForm } from "./period-filters";

const card = "rounded-2xl border border-border bg-card p-6";

const TYPE_LABEL: Record<string, string> = {
  inactividad: "Inactividad",
  sentimiento: "Caída de sentimiento",
  compromiso_vencido: "Compromisos vencidos",
};

function Kpi({ label, value, hint, tone }: { label: string; value: number; hint?: string; tone?: "alert" }) {
  return (
    <div className={card}>
      <div className="text-[13px] font-semibold text-muted-foreground">{label}</div>
      <div className={`mt-2 font-heading text-[38px] leading-none font-bold tracking-[-.02em] ${tone === "alert" && value > 0 ? "text-danger-foreground" : "text-primary"}`}>
        <CountUp value={value} />
      </div>
      {hint && <div className="mt-2 text-[13px] text-muted-foreground">{hint}</div>}
    </div>
  );
}

function number(value: string | number | null): string {
  if (value === null) return "—";
  return Number(value).toLocaleString("es-BO", { maximumFractionDigits: 2 });
}

/** CU14 · Dashboard ejecutivo de emprendimientos (solo lectura), por periodo y etapa. */
export async function DashboardScreen({ filters }: { filters: PeriodFilters }) {
  const user = await requireSession();
  if (!hasPermission(user, "reportes:consulta")) return <NoAccess section="Dashboard" />;

  const [d, stages] = await Promise.all([getDashboard(filters), listStages()]);
  const biggest = Math.max(1, ...d.por_etapa.map((s) => s.total));
  const scope = filters.etapa ? stages.find((s) => s.etapa_id === filters.etapa)?.nombre : null;

  return (
    <>
      <PageHeader
        title="Indicadores del programa"
        subtitle="Cómo avanzan los emprendimientos activos: etapas, mentorías, compromisos, alertas e indicadores."
      />
      <PeriodFiltersForm basePath="/dashboard" filters={filters} stages={stages} />

      <p className="mb-5 text-sm text-muted-foreground">
        {scope ? `Emprendimientos en ${scope}. ` : "Todos los emprendimientos activos. "}
        {filters.desde || filters.hasta
          ? `Periodo: ${filters.desde ?? "inicio"} a ${filters.hasta ?? "hoy"}. `
          : "Sin límite de periodo. "}
        Los compromisos pendientes y vencidos son los de hoy.
      </p>

      <div className="mb-6 grid grid-cols-[repeat(auto-fit,minmax(210px,1fr))] gap-4">
        <Kpi label="Emprendimientos" value={d.emprendimientos_total} hint={scope ? `en ${scope}` : "activos"} />
        <Kpi label="Sesiones realizadas" value={d.sesiones.realizadas} hint={`${d.sesiones.programadas} programadas · ${d.sesiones.canceladas} canceladas`} />
        <Kpi label="Avances registrados" value={d.avances} hint="por los emprendedores" />
        <Kpi label="Alertas sin resolver" value={d.alertas.abiertas + d.alertas.revisadas} tone="alert" hint={`${d.alertas.abiertas} abiertas · ${d.alertas.revisadas} revisadas`} />
        <Kpi label="Compromisos vencidos" value={d.compromisos.vencidos} tone="alert" hint={`${d.compromisos.pendientes} pendientes · ${d.compromisos.cumplidos_periodo} cumplidos en el periodo`} />
      </div>

      <div className="flex flex-wrap items-start gap-6">
        <section className={`${card} min-w-[300px] flex-[1_1_420px]`}>
          <h2 className="mb-4 font-heading text-lg font-semibold">Emprendimientos por etapa</h2>
          <ul className="flex flex-col gap-3.5">
            {d.por_etapa.map((s) => (
              <li key={s.etapa_id}>
                <div className="mb-1.5 flex items-baseline justify-between gap-3 text-sm">
                  <span className={`font-semibold ${s.etapa_id === filters.etapa ? "text-primary" : ""}`}>{s.etapa}</span>
                  <span className="font-bold">{s.total}</span>
                </div>
                <div className="h-2.5 overflow-hidden rounded-full bg-muted" aria-hidden="true">
                  <div className="h-full rounded-full bg-primary" style={{ width: `${(s.total / biggest) * 100}%` }} />
                </div>
              </li>
            ))}
          </ul>
        </section>

        <section className={`${card} min-w-[300px] flex-[1_1_320px]`}>
          <h2 className="mb-4 font-heading text-lg font-semibold">Alertas por tipo</h2>
          {Object.keys(d.alertas.por_tipo).length === 0 ? (
            <p className="text-sm text-muted-foreground">Sin alertas en este periodo.</p>
          ) : (
            <ul>
              {Object.entries(d.alertas.por_tipo).map(([tipo, total]) => (
                <li key={tipo} className="flex justify-between gap-3 border-t border-muted py-2.5 text-sm first:border-t-0">
                  <span>{TYPE_LABEL[tipo] ?? tipo}</span>
                  <span className="font-bold">{total}</span>
                </li>
              ))}
            </ul>
          )}
          <p className="mt-3 text-[13px] text-muted-foreground">
            {d.alertas.atendidas} atendidas · {d.alertas.descartadas} descartadas
          </p>
        </section>
      </div>

      <section className={`${card} mt-6`}>
        <h2 className="mb-3 font-heading text-lg font-semibold">Indicadores registrados</h2>
        {d.indicadores.length === 0 ? (
          <p className="text-sm text-muted-foreground">No se registraron valores de indicadores en este periodo.</p>
        ) : (
          <div className="relative overflow-x-auto">
            <table className="w-full min-w-[420px] border-collapse text-left text-sm">
              <thead>
                <tr className="text-[13px] font-semibold text-muted-foreground">
                  <th scope="col" className="py-2.5 pr-4">Indicador</th>
                  <th scope="col" className="px-4 py-2.5">Registros</th>
                  <th scope="col" className="px-4 py-2.5">Promedio</th>
                </tr>
              </thead>
              <tbody>
                {d.indicadores.map((i) => (
                  <tr key={i.tipo_indicador_id} className="border-t border-muted transition-colors hover:bg-row-hover">
                    <td className="py-3 pr-4 font-semibold">{i.nombre}</td>
                    <td className="px-4 py-3">{i.registros}</td>
                    <td className="px-4 py-3">
                      {number(i.promedio)} {i.unidad ?? ""}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </>
  );
}
