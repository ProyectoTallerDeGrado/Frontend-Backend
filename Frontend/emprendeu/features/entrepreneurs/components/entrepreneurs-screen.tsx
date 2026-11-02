import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { Pagination } from "@/components/layout/pagination";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { ENTREPRENEURS_PAGE_SIZE, listEntrepreneurs } from "../server/queries";
import { RegisterEntrepreneurSheet } from "./register-entrepreneur-sheet";

function href(q: string, page?: number): string {
  const search = new URLSearchParams();
  if (q) search.set("q", q);
  if (page && page > 1) search.set("page", String(page));
  const query = search.toString();
  return query ? `/entrepreneurs?${query}` : "/entrepreneurs";
}

/** CU04 · Emprendedores registrados; la coordinación registra nuevos (usuario y perfil juntos). */
export async function EntrepreneursScreen({ q, page }: { q: string; page: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "emprendedores:consulta")) return <NoAccess section="Emprendedores" />;
  const result = await listEntrepreneurs({ q, page });
  const canRegister = hasPermission(user, "emprendedores:registro");

  return (
    <>
      <PageHeader
        title="Emprendedores"
        subtitle="Personas registradas en la plataforma. El documento de identidad no puede repetirse."
        actions={canRegister ? <RegisterEntrepreneurSheet /> : undefined}
      />
      <form method="get" action="/entrepreneurs" className="mb-5 flex flex-wrap items-end gap-3">
        <label className="flex min-w-[240px] flex-[1_1_280px] flex-col gap-1.5 text-[13px] font-semibold">
          Buscar
          <input
            type="search"
            name="q"
            defaultValue={q}
            placeholder="Nombre, correo o documento"
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
          <Link href={href("")} className="inline-flex min-h-11 items-center px-2 text-sm font-semibold text-primary">
            Quitar búsqueda
          </Link>
        )}
      </form>

      <div className="overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[760px] border-collapse text-left text-sm">
          <thead>
            <tr className="bg-[#f4f6fb] text-[12px] font-bold tracking-[.06em] text-muted-foreground uppercase">
              <th scope="col" className="px-5 py-3.5">Emprendedor</th>
              <th scope="col" className="px-5 py-3.5">Documento</th>
              <th scope="col" className="px-5 py-3.5">Emprendimientos</th>
              <th scope="col" className="px-5 py-3.5">Registro</th>
            </tr>
          </thead>
          <tbody>
            {result.items.length === 0 && (
              <tr>
                <td colSpan={4} className="px-5 py-10 text-center text-muted-foreground">
                  No hay emprendedores con ese criterio.
                </td>
              </tr>
            )}
            {result.items.map((e) => (
              <tr key={e.emprendedor_id} className="border-t border-[#eef2fa] align-middle">
                <td className="px-5 py-3.5">
                  <div className="font-semibold">{`${e.nombre ?? ""} ${e.apellido ?? ""}`.trim()}</div>
                  <div className="text-[13px] text-muted-foreground">{e.email}</div>
                </td>
                <td className="px-5 py-3.5">{e.documento_identidad ?? "—"}</td>
                <td className="px-5 py-3.5">{e.emprendimientos.length}</td>
                <td className="px-5 py-3.5 text-muted-foreground">{e.fecha_registro ? formatDateTime(e.fecha_registro) : "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination page={result.page} pageSize={ENTREPRENEURS_PAGE_SIZE} total={result.total} hrefFor={(p) => href(q, p)} />
    </>
  );
}
