import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { Pagination } from "@/components/layout/pagination";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { TRAINING_PAGE_SIZE, listTrainings } from "../server/queries";
import type { TrainingFilters } from "../types";
import { TrainingFormSheet } from "./training-form";
import { filterPillClass } from "@/components/data/filter-pills";

const ESTADOS = [
  { value: "", label: "Todas" },
  { value: "programada", label: "Programadas" },
  { value: "realizada", label: "Realizadas" },
  { value: "cancelada", label: "Canceladas" },
] as const;

function hrefFor(f: TrainingFilters): string {
  const search = new URLSearchParams();
  if (f.estado) search.set("estado", f.estado);
  if (f.page && f.page > 1) search.set("page", String(f.page));
  const query = search.toString();
  return query ? `/training?${query}` : "/training";
}

/** CU27 · Lista de capacitaciones del programa; coordinación las crea y edita. */
export async function TrainingScreen({ filters }: { filters: TrainingFilters }) {
  const user = await requireSession();
  if (!hasPermission(user, "asesorias:consulta")) return <NoAccess section="Capacitaciones" />;

  const result = await listTrainings(filters);
  const canCreate = hasPermission(user, "asesorias:registro");

  return (
    <>
      <PageHeader
        title="Capacitaciones"
        subtitle="Talleres y charlas del programa. Entra a una para ver sus participantes y registrar la asistencia."
        actions={canCreate ? <TrainingFormSheet /> : undefined}
      />
      <div className="mb-5 flex flex-wrap gap-2" role="group" aria-label="Filtrar por estado">
        {ESTADOS.map((e) => (
          <Link
            key={e.value}
            href={hrefFor({ estado: e.value || undefined })}
            aria-current={(filters.estado ?? "") === e.value ? "true" : undefined}
            className={filterPillClass((filters.estado ?? "") === e.value)}
          >
            {e.label}
          </Link>
        ))}
      </div>
      <div className="relative overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[760px] border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
              <th scope="col" className="px-5 py-3.5">Capacitación</th>
              <th scope="col" className="px-5 py-3.5">Fecha</th>
              <th scope="col" className="px-5 py-3.5">Modalidad</th>
              <th scope="col" className="px-5 py-3.5">Inscritos</th>
              <th scope="col" className="px-5 py-3.5">Estado</th>
            </tr>
          </thead>
          <tbody>
            {result.items.length === 0 && (
              <tr>
                <td colSpan={5} className="px-5 py-10 text-center text-muted-foreground">
                  No hay capacitaciones con ese criterio.
                </td>
              </tr>
            )}
            {result.items.map((t) => (
              <tr key={t.capacitacion_id} className="border-t border-muted transition-colors hover:bg-row-hover">
                <td className="px-5 py-3.5">
                  <Link href={`/training/${t.capacitacion_id}`} className="font-semibold text-primary hover:underline">
                    {t.titulo}
                  </Link>
                  {t.tipo && <div className="text-[13px] text-muted-foreground capitalize">{t.tipo}</div>}
                </td>
                <td className="px-5 py-3.5 text-muted-foreground">{formatDateTime(t.fecha)}</td>
                <td className="px-5 py-3.5 capitalize">{t.modalidad ?? "—"}</td>
                <td className="px-5 py-3.5">{t.total_inscritos}</td>
                <td className="px-5 py-3.5 font-semibold capitalize">{t.estado ?? "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination page={result.page} pageSize={TRAINING_PAGE_SIZE} total={result.total} hrefFor={(p) => hrefFor({ ...filters, page: p })} />
    </>
  );
}
