import Link from "next/link";

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

const BADGE: Record<Admission["estado"], string> = {
  pendiente: "bg-[#fff0cc] text-[#5e3f00]",
  admitida: "bg-success-tint text-success-foreground",
  rechazada: "bg-[#ffe3e8] text-[#8f0f25]",
};

function href(f: AdmissionFilters, page?: number): string {
  const search = new URLSearchParams();
  if (f.estado) search.set("estado", f.estado);
  if (f.q) search.set("q", f.q);
  if (page && page > 1) search.set("page", String(page));
  const query = search.toString();
  return query ? `/admissions?${query}` : "/admissions";
}

const pill = (active: boolean) =>
  `inline-flex min-h-11 items-center rounded-full border-[1.5px] px-4 text-sm font-semibold outline-none transition-all focus-visible:ring-3 focus-visible:ring-primary/30 ${active ? "border-navy-900 bg-navy-900 text-white" : "border-border-strong bg-card text-foreground hover:bg-blue-50"}`;

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
      <div role="group" aria-label="Estado" className="mb-4 flex flex-wrap gap-2">
        {STATES.map((s) => {
          const active = (filters.estado ?? "") === s.value;
          return (
            <Link
              key={s.value}
              href={href({ ...filters, estado: s.value ? (s.value as Admission["estado"]) : undefined })}
              aria-current={active ? "true" : undefined}
              className={pill(active)}
            >
              {s.label}
            </Link>
          );
        })}
      </div>
      <form method="get" action="/admissions" className="mb-5 flex flex-wrap items-end gap-3">
        {filters.estado && <input type="hidden" name="estado" value={filters.estado} />}
        <label className="flex min-w-[240px] flex-[1_1_280px] flex-col gap-1.5 text-[13px] font-semibold">
          Buscar
          <input
            type="search"
            name="q"
            defaultValue={q}
            placeholder="Nombre, correo o emprendimiento"
            className="h-12 rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-[15px] font-normal outline-none focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15"
          />
        </label>
        <button
          type="submit"
          className="h-12 rounded-xl border-[1.5px] border-border-strong bg-card px-5 text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
        >
          Buscar
        </button>
      </form>

      <div className="overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[860px] border-collapse text-left text-sm">
          <thead>
            <tr className="bg-[#f4f6fb] text-[12px] font-bold tracking-[.06em] text-muted-foreground uppercase">
              <th scope="col" className="px-5 py-3.5">Postulante</th>
              <th scope="col" className="px-5 py-3.5">Emprendimiento</th>
              <th scope="col" className="px-5 py-3.5">Postuló</th>
              <th scope="col" className="px-5 py-3.5">Estado</th>
              <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>
            </tr>
          </thead>
          <tbody>
            {result.items.length === 0 && (
              <tr>
                <td colSpan={5} className="px-5 py-10 text-center text-muted-foreground">
                  No hay postulaciones con ese criterio.
                </td>
              </tr>
            )}
            {result.items.map((a) => (
              <tr key={a.postulacion_id} className="border-t border-[#eef2fa] align-top">
                <td className="px-5 py-3.5">
                  <div className="font-semibold">{`${a.nombre} ${a.apellido}`}</div>
                  <div className="text-[13px] text-muted-foreground">{a.email}</div>
                </td>
                <td className="px-5 py-3.5">
                  <div className="font-semibold">{a.nombre_emprendimiento}</div>
                  <div className="text-[13px] text-muted-foreground">{a.sector ?? "Sin sector"}</div>
                </td>
                <td className="px-5 py-3.5 text-muted-foreground">{formatDateTime(a.fecha_postulacion)}</td>
                <td className="px-5 py-3.5">
                  <span className={`rounded-full px-3 py-1 text-[13px] font-bold capitalize ${BADGE[a.estado]}`}>{a.estado}</span>
                </td>
                <td className="px-5 py-3 text-right">
                  <Link
                    href={`/admissions/${a.postulacion_id}`}
                    className="inline-flex min-h-11 items-center text-sm font-semibold text-primary hover:underline"
                  >
                    {a.estado === "pendiente" ? "Revisar" : "Ver"}
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination page={result.page} pageSize={ADMISSIONS_PAGE_SIZE} total={result.total} hrefFor={(p) => href(filters, p)} />
    </>
  );
}
