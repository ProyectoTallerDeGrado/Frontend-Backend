import Link from "next/link";

import type { Stage } from "@/features/ventures";

import type { PeriodFilters } from "../types";

type Props = {
  basePath: string;
  filters: PeriodFilters;
  stages: Stage[];
  /** Campos que deben conservarse al filtrar (p. ej. el tipo de reporte). */
  hidden?: Record<string, string>;
};

const input =
  "h-11 rounded-xl border-[1.5px] border-border-strong bg-card px-3 text-sm outline-none focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15";

/** Periodo (desde/hasta) y etapa: un formulario GET, así el filtro queda en la URL. */
export function PeriodFiltersForm({ basePath, filters, stages, hidden = {} }: Props) {
  const active = Boolean(filters.desde || filters.hasta || filters.etapa);
  const clear = new URLSearchParams(hidden).toString();
  return (
    <form method="get" action={basePath} className="mb-6 flex flex-wrap items-end gap-x-4 gap-y-3">
      {Object.entries(hidden).map(([name, value]) => (
        <input key={name} type="hidden" name={name} value={value} />
      ))}
      <label className="flex flex-col gap-1.5 text-[13px] font-semibold">
        Desde
        <input type="date" name="desde" defaultValue={filters.desde ?? ""} className={input} />
      </label>
      <label className="flex flex-col gap-1.5 text-[13px] font-semibold">
        Hasta
        <input type="date" name="hasta" defaultValue={filters.hasta ?? ""} className={input} />
      </label>
      <label className="flex flex-col gap-1.5 text-[13px] font-semibold">
        Etapa
        <select name="etapa" defaultValue={filters.etapa ? String(filters.etapa) : ""} className={`${input} min-w-[180px]`}>
          <option value="">Todas las etapas</option>
          {stages.map((s) => (
            <option key={s.etapa_id} value={s.etapa_id}>
              {s.nombre}
            </option>
          ))}
        </select>
      </label>
      <button
        type="submit"
        className="h-11 rounded-xl bg-primary px-5 text-sm font-bold text-primary-foreground outline-none hover:bg-primary/90 focus-visible:ring-3 focus-visible:ring-primary/30"
      >
        Aplicar
      </button>
      {active && (
        <Link
          href={clear ? `${basePath}?${clear}` : basePath}
          className="inline-flex min-h-11 items-center px-2 text-sm font-semibold text-primary"
        >
          Quitar filtros
        </Link>
      )}
    </form>
  );
}
