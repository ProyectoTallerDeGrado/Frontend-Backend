import Link from "next/link";

import { DataTable, EmptyRow, THead, Td, Th, Tr, rowLinkClass } from "@/components/data/data-table";
import { FilterPills } from "@/components/data/filter-pills";
import { SearchBar } from "@/components/data/search-bar";
import { StatusPill, type PillTone } from "@/components/data/status-pill";
import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { Pagination } from "@/components/layout/pagination";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { ADMISSIONS_PAGE_SIZE, listAdmissions } from "../server/queries";
import type { Admission, AdmissionFilters } from "../types";

const STATES = [
  { value: "", label: "Todas" },
  { value: "pendiente", label: "Pendientes" },
  { value: "admitida", label: "Admitidas" },
  { value: "rechazada", label: "Rechazadas" },
] as const;

const TONE: Record<Admission["estado"], PillTone> = { pendiente: "warning", admitida: "success", rechazada: "danger" };
const LABEL: Record<Admission["estado"], string> = { pendiente: "Pendiente", admitida: "Admitida", rechazada: "Rechazada" };

function href(f: AdmissionFilters, page?: number): string {
  const search = new URLSearchParams();
  if (f.estado) search.set("estado", f.estado);
  if (f.q) search.set("q", f.q);
  if (page && page > 1) search.set("page", String(page));
  const query = search.toString();
  return query ? `/admissions?${query}` : "/admissions";
}

/** CU26 · Postulaciones al programa para la coordinación. */
export async function AdmissionsScreen({ filters }: { filters: AdmissionFilters }) {
  const user = await requireSession();
  if (!hasPermission(user, "emprendedores:consulta")) return <NoAccess section="Admisiones" />;

  const result = await listAdmissions(filters);
  const q = filters.q ?? "";

  return (
    <>
      <PageHeader
        title="Admisión al programa"
        subtitle="Postulaciones de emprendedores. Admitir crea la cuenta y el emprendimiento; admitir o rechazar es definitivo."
      />
      <SearchBar
        action="/admissions"
        q={q}
        placeholder="Nombre, correo o emprendimiento"
        clearHref={href({ ...filters, q: undefined })}
        hidden={{ estado: filters.estado }}
      >
        <FilterPills
          label="Filtrar por estado"
          options={STATES.map((s) => ({
            label: s.label,
            href: href({ ...filters, estado: s.value ? (s.value as Admission["estado"]) : undefined }),
            active: (filters.estado ?? "") === s.value,
          }))}
        />
      </SearchBar>

      <DataTable minWidth={860} caption="Postulaciones">
        <THead>
          <Th>Postulante</Th>
          <Th>Emprendimiento</Th>
          <Th>Postuló</Th>
          <Th>Estado</Th>
          <Th>
            <span className="sr-only">Acciones</span>
          </Th>
        </THead>
        <tbody>
          {result.items.length === 0 && (
            <EmptyRow colSpan={5}>
              {q || filters.estado ? "Ninguna postulación coincide con el filtro." : "Todavía no llegaron postulaciones."}
            </EmptyRow>
          )}
          {result.items.map((a) => (
            <Tr key={a.postulacion_id} className="align-top">
              <Td>
                <div className="text-[15px] font-semibold">{`${a.nombre} ${a.apellido}`}</div>
                <div className="text-[13px] text-muted-foreground">{a.email}</div>
              </Td>
              <Td>
                <div className="font-semibold">{a.nombre_emprendimiento}</div>
                <div className="text-[13px] text-muted-foreground">{a.sector ?? "Sin sector"}</div>
              </Td>
              <Td className="text-muted-foreground">{formatDateTime(a.fecha_postulacion)}</Td>
              <Td>
                <StatusPill tone={TONE[a.estado]} dot>
                  {LABEL[a.estado]}
                </StatusPill>
              </Td>
              <Td className="text-right">
                <Link href={`/admissions/${a.postulacion_id}`} transitionTypes={["nav-forward"]} className={rowLinkClass}>
                  {a.estado === "pendiente" ? "Revisar" : "Ver"}
                </Link>
              </Td>
            </Tr>
          ))}
        </tbody>
      </DataTable>
      <Pagination page={result.page} pageSize={ADMISSIONS_PAGE_SIZE} total={result.total} hrefFor={(p) => href(filters, p)} />
    </>
  );
}
