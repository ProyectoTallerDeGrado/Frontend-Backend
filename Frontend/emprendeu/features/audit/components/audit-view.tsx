import Link from "next/link";

import { Pagination } from "@/components/layout/pagination";
import { formatWhen } from "@/lib/format";

import { AUDIT_PAGE_SIZE, listAudit } from "../server/queries";
import { AUDIT_FILTERS } from "../types";

type Props = { categoria: string; page: number };

const COLS = "grid-cols-[150px_190px_minmax(280px,1fr)_120px]";

function hrefFor(categoria: string, page = 1): string {
  const params = new URLSearchParams();
  if (categoria) params.set("categoria", categoria);
  if (page > 1) params.set("page", String(page));
  const query = params.toString();
  return query ? `/audit?${query}` : "/audit";
}

export async function AuditView({ categoria, page }: Props) {
  const data = await listAudit({ categoria, page });
  return (
    <div className="flex flex-col gap-[18px]">
      <div className="flex flex-wrap gap-2" role="group" aria-label="Filtrar por categoría">
        {AUDIT_FILTERS.map((f) => {
          const on = f.key === categoria;
          return (
            <Link
              key={f.key}
              href={hrefFor(f.key)}
              aria-current={on ? "true" : undefined}
              className={`inline-flex min-h-11 items-center rounded-full border-[1.5px] px-4 text-sm font-semibold outline-none transition-all focus-visible:ring-3 focus-visible:ring-primary/30 ${on ? "border-navy-900 bg-navy-900 text-white" : "border-border-strong bg-card hover:bg-blue-50"}`}
            >
              {f.label}
            </Link>
          );
        })}
      </div>
      <div className="overflow-x-auto overflow-y-hidden rounded-2xl border border-border bg-card">
        <div className="min-w-[840px]">
          <div
            className={`grid ${COLS} gap-4 border-b border-border bg-[#f8fafe] px-6 py-3.5 text-[13px] font-bold tracking-[.04em] text-muted-foreground uppercase`}
          >
            <span>Hora</span>
            <span>Actor</span>
            <span>Acción</span>
            <span>Resultado</span>
          </div>
          {data.items.map((a, i) => {
            const ok = a.resultado === "exitoso";
            return (
              <div
                key={a.bitacora_id}
                className={`grid ${COLS} animate-[fade-up_.4s_ease_both] items-center gap-4 border-b border-[#eef2fa] px-6 py-3.5 transition-colors hover:bg-[#f4f7ff]`}
                style={{ animationDelay: `${Math.min(i, 12) * 35}ms` }}
              >
                <span className="text-sm text-muted-foreground">{formatWhen(a.fecha)}</span>
                <span className="text-sm font-semibold">{a.actor ?? "Sistema"}</span>
                <span className="text-[15px]">
                  {a.descripcion}
                  {a.objeto && <span className="text-muted-foreground"> · {a.objeto}</span>}
                </span>
                <span>
                  <span
                    className={`inline-block rounded-full px-3 py-1 text-[13px] font-bold ${ok ? "bg-success-tint text-success-foreground" : "bg-[#ffe3e8] text-[#8f0f25]"}`}
                  >
                    {ok ? "Exitoso" : "Rechazado"}
                  </span>
                </span>
              </div>
            );
          })}
          {data.items.length === 0 && (
            <div className="px-6 py-10 text-center text-[15px] text-muted-foreground">
              No hay registros para este filtro.
            </div>
          )}
        </div>
      </div>
      <Pagination
        page={data.page}
        pageSize={AUDIT_PAGE_SIZE}
        total={data.total}
        hrefFor={(p) => hrefFor(categoria, p)}
      />
    </div>
  );
}
