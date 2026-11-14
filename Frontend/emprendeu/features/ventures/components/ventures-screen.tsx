import Link from "next/link";
import type { ReactNode } from "react";

import { DataTable, EmptyRow, THead, Td, Th, Tr } from "@/components/data/data-table";
import { FilterPills } from "@/components/data/filter-pills";
import { SearchBar } from "@/components/data/search-bar";
import { StatusPill, type PillTone } from "@/components/data/status-pill";
import { NoAccess } from "@/components/layout/no-access";
import { Pagination } from "@/components/layout/pagination";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { listEntrepreneurOptions } from "@/features/entrepreneurs";

import { roleLabel } from "../roles";
import { VENTURE_STATES } from "../schemas/ventures-schemas";
import { VENTURES_PAGE_SIZE, listStages, listVentures } from "../server/queries";
import { nextStage } from "../stages";
import { AdvanceStageSheet } from "./advance-stage-sheet";
import { ventureHref } from "./venture-header";
import { NewVentureSheet } from "./venture-form-sheet";

type Props = {
  q: string;
  estado: string;
  page: number;
  /** Columna extra que compone la página (p. ej. el asesor de cada emprendimiento, CU09). */
  extraColumn?: { header: string; cell: (venture: { id: number; name: string }) => ReactNode };
};

const STATE_LABEL: Record<string, string> = { activo: "Activo", pausado: "Pausado", cerrado: "Cerrado" };
const STATE_TONE: Record<string, PillTone> = { activo: "success", pausado: "warning", cerrado: "neutral" };

function href(q: string, estado: string, page?: number): string {
  const search = new URLSearchParams();
  if (q) search.set("q", q);
  if (estado) search.set("estado", estado);
  if (page && page > 1) search.set("page", String(page));
  const query = search.toString();
  return query ? `/ventures?${query}` : "/ventures";
}

/** CU12 · Emprendimientos con su etapa actual. El nombre abre la ficha; ahí se edita el equipo y los datos. */
export async function VenturesScreen({ q, estado, page, extraColumn }: Props) {
  const user = await requireSession();
  if (!hasPermission(user, "emprendedores:consulta")) return <NoAccess section="Emprendimientos" />;

  const [result, stages] = await Promise.all([listVentures({ q, estado, page }), listStages()]);
  const canChangeStage = hasPermission(user, "seguimiento:modificacion");
  const canCreate = hasPermission(user, "emprendedores:registro");
  const canFollow = hasPermission(user, "seguimiento:consulta");
  const entrepreneurs = canCreate ? await listEntrepreneurOptions() : [];
  const columns = 4 + (extraColumn ? 1 : 0) + (canChangeStage ? 1 : 0);

  return (
    <>
      <PageHeader
        title="Emprendimientos"
        subtitle="Etapa y equipo de cada emprendimiento. Abre uno para ver su progreso, seguimiento y documentos."
        actions={canCreate ? <NewVentureSheet entrepreneurs={entrepreneurs} /> : undefined}
      />
      <SearchBar
        action="/ventures"
        q={q}
        placeholder="Nombre del emprendimiento"
        clearHref={href("", estado)}
        hidden={{ estado }}
      >
        <FilterPills
          label="Filtrar por estado"
          options={[
            { label: "Todos", href: href(q, ""), active: !estado },
            ...VENTURE_STATES.map((s) => ({ label: STATE_LABEL[s], href: href(q, s), active: estado === s })),
          ]}
        />
      </SearchBar>

      <DataTable minWidth={extraColumn ? 1040 : 900} caption="Emprendimientos">
        <THead>
          <Th>Emprendimiento</Th>
          <Th>Equipo</Th>
          {extraColumn && <Th>{extraColumn.header}</Th>}
          <Th>Etapa actual</Th>
          <Th>Estado</Th>
          {canChangeStage && (
            <Th>
              <span className="sr-only">Acciones</span>
            </Th>
          )}
        </THead>
        <tbody>
          {result.items.length === 0 && (
            <EmptyRow colSpan={columns}>
              {q || estado ? "Ningún emprendimiento coincide con el filtro." : "Todavía no hay emprendimientos registrados."}
            </EmptyRow>
          )}
          {result.items.map((v) => {
            const next = nextStage(stages, v.etapa_actual);
            return (
              <Tr key={v.emprendimiento_id}>
                <Td className="max-w-[300px]">
                  <Link
                    href={ventureHref(v.emprendimiento_id, canFollow)}
                    transitionTypes={["nav-forward"]}
                    className="group/name block rounded-lg outline-none focus-visible:ring-3 focus-visible:ring-primary/30"
                  >
                    <span className="block truncate text-[15px] font-semibold text-foreground group-hover/name:text-primary group-hover/name:underline">
                      {v.nombre}
                    </span>
                    <span className="block truncate text-[13px] text-muted-foreground">{v.sector ?? "Sin sector"}</span>
                  </Link>
                </Td>
                <Td>
                  {v.integrantes.length === 0 ? (
                    <span className="text-muted-foreground">Sin integrantes</span>
                  ) : (
                    <ul className="flex flex-col gap-0.5">
                      {v.integrantes.map((m) => (
                        <li key={m.emprendedor_id} className="text-[13px] leading-snug">
                          <span className="font-semibold">{`${m.nombre ?? ""} ${m.apellido ?? ""}`.trim() || m.email}</span>
                          <span className="text-muted-foreground"> ({roleLabel(m.rol_en_emprendimiento).toLowerCase()})</span>
                        </li>
                      ))}
                    </ul>
                  )}
                </Td>
                {extraColumn && <Td>{extraColumn.cell({ id: v.emprendimiento_id, name: v.nombre })}</Td>}
                <Td>
                  <StatusPill tone={v.etapa_actual ? "info" : "neutral"}>{v.etapa_actual?.nombre ?? "Sin etapa"}</StatusPill>
                </Td>
                <Td>
                  {v.estado ? (
                    <StatusPill tone={STATE_TONE[v.estado] ?? "neutral"} dot>
                      {STATE_LABEL[v.estado] ?? v.estado}
                    </StatusPill>
                  ) : (
                    <span className="text-muted-foreground">—</span>
                  )}
                </Td>
                {canChangeStage && (
                  <Td className="text-right">
                    {next ? (
                      <AdvanceStageSheet venture={v} next={next} />
                    ) : (
                      <span className="text-[13px] text-muted-foreground">Última etapa</span>
                    )}
                  </Td>
                )}
              </Tr>
            );
          })}
        </tbody>
      </DataTable>
      <Pagination
        page={result.page}
        pageSize={VENTURES_PAGE_SIZE}
        total={result.total}
        hrefFor={(p) => href(q, estado, p)}
      />
    </>
  );
}
