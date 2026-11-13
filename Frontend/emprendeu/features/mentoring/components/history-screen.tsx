import Link from "next/link";
import {
  CalendarCheck,
  Flag,
  Handshake,
  Lightbulb,
  Rocket,
  TrendingUp,
  type LucideIcon,
} from "lucide-react";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { getVentureHistory } from "../server/queries";
import type { HistoryEvent, HistoryFilters, HistoryKind } from "../types";

const KIND: Record<HistoryEvent["tipo"], { label: string; icon: LucideIcon; tone: string }> = {
  sesion: { label: "Sesión", icon: CalendarCheck, tone: "bg-blue-50 text-primary" },
  avance: { label: "Avance", icon: TrendingUp, tone: "bg-success-tint text-success-foreground" },
  hito: { label: "Hito", icon: Flag, tone: "bg-[#fff0cc] text-[#5e3f00]" },
  recomendacion: { label: "Recomendación", icon: Lightbulb, tone: "bg-[#fff0cc] text-[#5e3f00]" },
  compromiso: { label: "Compromiso", icon: Handshake, tone: "bg-blue-50 text-primary" },
  etapa: { label: "Etapa", icon: Rocket, tone: "bg-navy-900 text-white" },
};

type Props = { ventureId: number; ventureName: string; filters: HistoryFilters };

const dateInput =
  "h-11 rounded-xl border-[1.5px] border-border-strong bg-card px-3 text-sm font-normal outline-none focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15";

function historyHref(base: string, f: Partial<HistoryFilters>): string {
  const search = new URLSearchParams();
  if (f.orden && f.orden !== "asc") search.set("orden", f.orden);
  for (const tipo of f.tipos ?? []) search.append("tipo", tipo);
  if (f.desde) search.set("desde", f.desde);
  if (f.hasta) search.set("hasta", f.hasta);
  const query = search.toString();
  return query ? `${base}?${query}` : base;
}

/** CU19 · Historial del emprendimiento: orden cronológico, tipos de evento y periodo (todo en la URL). */
export async function HistoryScreen({ ventureId, ventureName, filters }: Props) {
  const user = await requireSession();
  if (!hasPermission(user, "seguimiento:consulta")) return <NoAccess section="Historial" />;

  const { orden } = filters;
  const events = await getVentureHistory(ventureId, filters);
  const base = `/ventures/${ventureId}/history`;
  const other = orden === "asc" ? "desc" : "asc";
  const filtered = filters.tipos.length > 0 || Boolean(filters.desde) || Boolean(filters.hasta);

  return (
    <>
      <PageHeader
        title={`Historial · ${ventureName}`}
        subtitle="Sesiones, avances, hitos, recomendaciones, compromisos y cambios de etapa del emprendimiento."
        actions={
          <Link
            href={historyHref(base, { ...filters, orden: other })}
            className="inline-flex min-h-11 items-center rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
          >
            {orden === "asc" ? "Ver lo más reciente primero" : "Ver en orden cronológico"}
          </Link>
        }
      />
      <Link href="/ventures" className="mb-5 inline-flex min-h-11 items-center text-sm font-semibold text-primary">
        ← Volver a emprendimientos
      </Link>

      <form
        method="get"
        action={base}
        aria-label="Filtros del historial"
        className="mb-6 flex flex-col gap-4 rounded-2xl border border-border bg-card p-5"
      >
        {orden === "desc" && <input type="hidden" name="orden" value="desc" />}
        <fieldset className="flex flex-wrap gap-x-5 gap-y-2">
          <legend className="mb-2 text-[13px] font-semibold">Tipo de evento</legend>
          {(Object.keys(KIND) as HistoryKind[]).map((tipo) => (
            <label key={tipo} className="inline-flex min-h-11 items-center gap-2 text-sm">
              <input
                type="checkbox"
                name="tipo"
                value={tipo}
                defaultChecked={filters.tipos.includes(tipo)}
                className="size-5 accent-[var(--primary)]"
              />
              {KIND[tipo].label}
            </label>
          ))}
        </fieldset>
        <div className="flex flex-wrap items-end gap-3">
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
            Aplicar filtros
          </button>
          {filtered && (
            <Link
              href={historyHref(base, { orden })}
              className="inline-flex min-h-11 items-center px-2 text-sm font-semibold text-primary"
            >
              Quitar filtros
            </Link>
          )}
        </div>
      </form>

      {events.length === 0 ? (
        <p className="rounded-2xl border border-border bg-card p-8 text-center text-muted-foreground">
          {filtered
            ? "No hay eventos con esos filtros."
            : "Este emprendimiento todavía no tiene actividad registrada."}
        </p>
      ) : (
        <ol className="flex flex-col">
          {events.map((e) => {
            const kind = KIND[e.tipo];
            const Icon = kind.icon;
            return (
              <li key={`${e.tipo}-${e.referencia_id}`} className="flex gap-4">
                <div className="flex flex-col items-center">
                  <span className={`flex size-10 shrink-0 items-center justify-center rounded-full ${kind.tone}`}>
                    <Icon aria-hidden="true" className="size-[18px]" />
                  </span>
                  <span aria-hidden="true" className="w-px flex-1 bg-border" />
                </div>
                <div className="mb-4 min-w-0 flex-1 rounded-2xl border border-border bg-card px-5 py-4">
                  <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
                    <div className="text-[13px] font-bold tracking-[.06em] text-muted-foreground uppercase">
                      {kind.label}
                    </div>
                    <div className="text-[13px] text-muted-foreground">{e.fecha ? formatDateTime(e.fecha) : "Sin fecha"}</div>
                  </div>
                  <div className="mt-1 text-[15px] font-semibold">{e.titulo}</div>
                  {e.detalle && <p className="mt-1 text-sm leading-normal text-muted-foreground">{e.detalle}</p>}
                  <div className="mt-2 flex flex-wrap gap-x-3 gap-y-1 text-[13px] text-muted-foreground">
                    {e.estado && <span className="font-semibold">{e.estado.charAt(0).toUpperCase() + e.estado.slice(1)}</span>}
                    {e.autor && <span>por {e.autor}</span>}
                  </div>
                </div>
              </li>
            );
          })}
        </ol>
      )}
    </>
  );
}
