import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { Pagination } from "@/components/layout/pagination";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { listEntrepreneurOptions } from "@/features/entrepreneurs";

import { VENTURES_PAGE_SIZE, listStages, listVentures } from "../server/queries";
import type { Stage } from "../types";
import { AdvanceStageSheet } from "./advance-stage-sheet";
import { roleLabel } from "./team-picker";
import { TeamSheet } from "./team-sheet";
import { EditVentureSheet, NewVentureSheet } from "./venture-form-sheet";

type Props = { q: string; estado: string; page: number };

/** Etapa activa inmediatamente siguiente a `current` (la misma regla que aplica el backend). */
function nextStage(stages: Stage[], current: Stage | null): Stage | null {
  const active = stages.filter((s) => s.estado === "activa").sort((a, b) => (a.orden ?? 0) - (b.orden ?? 0));
  if (!current) return active[0] ?? null;
  return active.find((s) => (s.orden ?? 0) > (current.orden ?? 0)) ?? null;
}

function href(q: string, estado: string, page?: number): string {
  const search = new URLSearchParams();
  if (q) search.set("q", q);
  if (estado) search.set("estado", estado);
  if (page && page > 1) search.set("page", String(page));
  const query = search.toString();
  return query ? `/ventures?${query}` : "/ventures";
}

/** CU12 · Emprendimientos con su etapa actual; coordinación los avanza a la etapa siguiente. */
export async function VenturesScreen({ q, estado, page }: Props) {
  const user = await requireSession();
  if (!hasPermission(user, "emprendedores:consulta")) return <NoAccess section="Emprendimientos" />;

  const [result, stages] = await Promise.all([listVentures({ q, estado, page }), listStages()]);
  const canChangeStage = hasPermission(user, "seguimiento:modificacion");
  const canCreate = hasPermission(user, "emprendedores:registro");
  const canEdit = hasPermission(user, "emprendedores:modificacion");
  const canSeeProgress = hasPermission(user, "seguimiento:consulta");
  const entrepreneurs = canCreate || canEdit ? await listEntrepreneurOptions() : [];
  const columns = 6 + (canChangeStage || canEdit ? 1 : 0);

  return (
    <>
      <PageHeader
        title="Emprendimientos"
        subtitle="Etapa y equipo de cada emprendimiento. La coordinación arma el equipo y avanza la etapa, sin saltos."
        actions={canCreate ? <NewVentureSheet entrepreneurs={entrepreneurs} /> : undefined}
      />
      <form method="get" action="/ventures" className="mb-5 flex flex-wrap items-end gap-3">
        <label className="flex min-w-[240px] flex-[1_1_280px] flex-col gap-1.5 text-[13px] font-semibold">
          Buscar
          <input
            type="search"
            name="q"
            defaultValue={q}
            placeholder="Nombre del emprendimiento"
            className="h-12 rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-[15px] font-normal outline-none focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15"
          />
        </label>
        <button
          type="submit"
          className="h-12 rounded-xl border-[1.5px] border-border-strong bg-card px-5 text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
        >
          Buscar
        </button>
        {q && (
          <Link href={href("", estado)} className="inline-flex min-h-11 items-center px-2 text-sm font-semibold text-primary">
            Quitar búsqueda
          </Link>
        )}
      </form>

      <div className="overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[1180px] border-collapse text-left text-sm">
          <thead>
            <tr className="bg-[#f4f6fb] text-[12px] font-bold tracking-[.06em] text-muted-foreground uppercase">
              <th scope="col" className="px-5 py-3.5">Emprendimiento</th>
              <th scope="col" className="px-5 py-3.5">Equipo</th>
              <th scope="col" className="px-5 py-3.5">Sector</th>
              <th scope="col" className="px-5 py-3.5">Etapa actual</th>
              <th scope="col" className="px-5 py-3.5">Estado</th>
              <th scope="col" className="px-5 py-3.5"><span className="sr-only">Consultas</span></th>
              {(canChangeStage || canEdit) && <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>}
            </tr>
          </thead>
          <tbody>
            {result.items.length === 0 && (
              <tr>
                <td colSpan={columns} className="px-5 py-10 text-center text-muted-foreground">
                  No hay emprendimientos con ese criterio.
                </td>
              </tr>
            )}
            {result.items.map((v) => {
              const next = nextStage(stages, v.etapa_actual);
              return (
                <tr key={v.emprendimiento_id} className="border-t border-[#eef2fa] align-middle">
                  <td className="px-5 py-3.5 font-semibold">{v.nombre}</td>
                  <td className="px-5 py-3.5">
                    {v.integrantes.length === 0 ? (
                      <span className="text-muted-foreground">Sin integrantes</span>
                    ) : (
                      <ul className="flex flex-col gap-0.5">
                        {v.integrantes.map((m) => (
                          <li key={m.emprendedor_id} className="text-[13px] leading-snug">
                            <span className="font-semibold">{`${m.nombre ?? ""} ${m.apellido ?? ""}`.trim() || m.email}</span>
                            <span className="text-muted-foreground"> · {roleLabel(m.rol_en_emprendimiento)}</span>
                          </li>
                        ))}
                      </ul>
                    )}
                  </td>
                  <td className="px-5 py-3.5 text-muted-foreground">{v.sector ?? "—"}</td>
                  <td className="px-5 py-3.5">
                    <span className="rounded-full bg-blue-50 px-3 py-1 text-[13px] font-bold text-primary">
                      {v.etapa_actual?.nombre ?? "Sin etapa"}
                    </span>
                  </td>
                  <td className="px-5 py-3.5 capitalize text-muted-foreground">{v.estado ?? "—"}</td>
                  <td className="px-5 py-3.5 text-right">
                    <div className="flex justify-end gap-4">
                      {canSeeProgress && (
                        <Link
                          href={`/ventures/${v.emprendimiento_id}/progress`}
                          className="inline-flex min-h-11 items-center text-sm font-semibold text-primary hover:underline"
                        >
                          Progreso
                        </Link>
                      )}
                      <Link
                        href={`/ventures/${v.emprendimiento_id}/history`}
                        className="inline-flex min-h-11 items-center text-sm font-semibold text-primary hover:underline"
                      >
                        Historial
                      </Link>
                    </div>
                  </td>
                  {(canChangeStage || canEdit) && (
                    <td className="px-5 py-3 text-right">
                      <div className="flex justify-end gap-2">
                        {canEdit && <TeamSheet venture={v} entrepreneurs={entrepreneurs} />}
                        {canEdit && <EditVentureSheet venture={v} />}
                        {canChangeStage &&
                          (next ? (
                            <AdvanceStageSheet venture={v} next={next} />
                          ) : (
                            <span className="inline-flex items-center text-[13px] text-muted-foreground">Última etapa</span>
                          ))}
                      </div>
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <Pagination
        page={result.page}
        pageSize={VENTURES_PAGE_SIZE}
        total={result.total}
        hrefFor={(p) => href(q, estado, p)}
      />
    </>
  );
}
