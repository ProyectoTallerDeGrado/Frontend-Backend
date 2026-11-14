import { DataTable, EmptyRow, THead, Td, Th, Tr } from "@/components/data/data-table";
import { SearchBar } from "@/components/data/search-bar";
import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { Pagination } from "@/components/layout/pagination";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime, initials } from "@/lib/format";

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
      <SearchBar action="/entrepreneurs" q={q} placeholder="Nombre, correo o documento" clearHref={href("")} />

      <DataTable minWidth={760} caption="Emprendedores">
        <THead>
          <Th>Emprendedor</Th>
          <Th>Documento</Th>
          <Th>Emprendimientos</Th>
          <Th>Registro</Th>
        </THead>
        <tbody>
          {result.items.length === 0 && (
            <EmptyRow colSpan={4}>
              {q ? "Ningún emprendedor coincide con la búsqueda." : "Todavía no hay emprendedores. Registra el primero con «Nuevo emprendedor»."}
            </EmptyRow>
          )}
          {result.items.map((e) => {
            const name = `${e.nombre ?? ""} ${e.apellido ?? ""}`.trim() || e.email || "Sin nombre";
            return (
              <Tr key={e.emprendedor_id}>
                <Td>
                  <div className="flex items-center gap-3">
                    <span
                      aria-hidden="true"
                      className="flex size-10 shrink-0 items-center justify-center rounded-full bg-success-tint text-[13px] font-bold text-success-foreground"
                    >
                      {initials(name)}
                    </span>
                    <div className="min-w-0">
                      <div className="truncate text-[15px] font-semibold">{name}</div>
                      <div className="truncate text-[13px] text-muted-foreground">{e.email}</div>
                    </div>
                  </div>
                </Td>
                <Td className="tabular-nums">{e.documento_identidad ?? "—"}</Td>
                <Td>
                  {e.emprendimientos.length === 0 ? (
                    <span className="text-muted-foreground">Ninguno</span>
                  ) : (
                    <span className="font-semibold tabular-nums">{e.emprendimientos.length}</span>
                  )}
                </Td>
                <Td className="text-muted-foreground">{e.fecha_registro ? formatDateTime(e.fecha_registro) : "—"}</Td>
              </Tr>
            );
          })}
        </tbody>
      </DataTable>
      <Pagination page={result.page} pageSize={ENTREPRENEURS_PAGE_SIZE} total={result.total} hrefFor={(p) => href(q, p)} />
    </>
  );
}
