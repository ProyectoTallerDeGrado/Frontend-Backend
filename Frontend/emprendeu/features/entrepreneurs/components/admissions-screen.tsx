import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { Pagination } from "@/components/layout/pagination";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { APPLICATIONS_PAGE_SIZE, listApplications } from "../server/queries";
import { DecideApplicationSheet } from "./decide-application-sheet";

const TABS = [
  { value: "pendiente", label: "Pendientes" },
  { value: "admitida", label: "Admitidas" },
  { value: "rechazada", label: "Rechazadas" },
] as const;

const TONE: Record<string, string> = {
  pendiente: "bg-blue-50 text-primary",
  admitida: "bg-success-tint text-success-foreground",
  rechazada: "bg-[#ffe3e8] text-[#8f0f25]",
};

function href(estado: string, q: string, page?: number): string {
  const search = new URLSearchParams({ estado });
  if (q) search.set("q", q);
  if (page && page > 1) search.set("page", String(page));
  return `/admissions?${search}`;
}

/** CU26 · Postulaciones al programa: la coordinación las revisa, admite o rechaza (decisión definitiva). */
export async function AdmissionsScreen({ estado, q, page }: { estado: string; q: string; page: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "emprendedores:consulta")) return <NoAccess section="Admisión" />;
  const canDecide = hasPermission(user, "emprendedores:registro");
  const current = TABS.some((t) => t.value === estado) ? estado : "pendiente";
  const result = await listApplications({ estado: current, q, page });

  return (
    <>
      <PageHeader
        title="Admisión"
        subtitle="Postulaciones al programa. Al admitir se crea la cuenta del emprendedor y su emprendimiento; una decisión no se puede cambiar."
        actions={
          <Link
            href="/postular"
            target="_blank"
            className="inline-flex min-h-11 items-center rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
          >
            Ver formulario público
          </Link>
        }
      />
      <nav aria-label="Estado de la postulación" className="mb-5 flex flex-wrap gap-2">
        {TABS.map((t) => (
          <Link
            key={t.value}
            href={href(t.value, q)}
            aria-current={t.value === current ? "page" : undefined}
            className={`inline-flex min-h-11 items-center rounded-xl px-4 text-sm font-semibold ${
              t.value === current ? "bg-primary text-primary-foreground" : "border-[1.5px] border-border-strong bg-card hover:bg-blue-50"
            }`}
          >
            {t.label}
          </Link>
        ))}
      </nav>
      <form method="get" action="/admissions" className="mb-5 flex flex-wrap items-end gap-3">
        <input type="hidden" name="estado" value={current} />
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
        <table className="w-full min-w-[820px] border-collapse text-left text-sm">
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
                  No hay postulaciones {current === "pendiente" ? "pendientes" : current === "admitida" ? "admitidas" : "rechazadas"}.
                </td>
              </tr>
            )}
            {result.items.map((a) => (
              <tr key={a.postulacion_id} className="border-t border-[#eef2fa] align-middle">
                <td className="px-5 py-3.5">
                  <div className="font-semibold">{`${a.nombre} ${a.apellido}`}</div>
                  <div className="text-[13px] text-muted-foreground">{a.email}</div>
                </td>
                <td className="px-5 py-3.5">
                  <div className="font-semibold">{a.nombre_emprendimiento}</div>
                  <div className="text-[13px] text-muted-foreground">{a.sector ?? "—"}</div>
                </td>
                <td className="px-5 py-3.5 text-muted-foreground">{formatDateTime(a.fecha_postulacion)}</td>
                <td className="px-5 py-3.5">
                  <span className={`rounded-full px-3 py-1 text-[13px] font-bold capitalize ${TONE[a.estado] ?? "bg-muted"}`}>{a.estado}</span>
                </td>
                <td className="px-5 py-3 text-right">
                  <DecideApplicationSheet application={a} canDecide={canDecide} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination page={result.page} pageSize={APPLICATIONS_PAGE_SIZE} total={result.total} hrefFor={(p) => href(current, q, p)} />
    </>
  );
}
