import Link from "next/link";
import { ChevronLeft, ChevronRight } from "lucide-react";
import type { ReactNode } from "react";

type PaginationProps = {
  page: number;
  pageSize: number;
  total: number;
  /** Construye la URL de una página (conserva los filtros). */
  hrefFor: (page: number) => string;
};

const base =
  "inline-flex min-h-11 items-center gap-1 rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-sm font-semibold";

/** En el primer o último extremo no hay a dónde ir: se pinta un texto apagado, no un enlace enfocable. */
function Step({ href, children }: { href: string | null; children: ReactNode }) {
  if (href === null) {
    return (
      <span aria-disabled="true" className={`${base} opacity-45`}>
        {children}
      </span>
    );
  }
  return (
    <Link href={href} className={`${base} outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30`}>
      {children}
    </Link>
  );
}

export function Pagination({ page, pageSize, total, hrefFor }: PaginationProps) {
  const pages = Math.max(1, Math.ceil(total / pageSize));
  if (pages <= 1) return null;
  return (
    <nav aria-label="Paginación" className="flex flex-wrap items-center justify-between gap-4 pt-2 text-sm">
      <span className="text-muted-foreground">
        Página {page} de {pages} · {total} registros
      </span>
      <div className="flex gap-2">
        <Step href={page > 1 ? hrefFor(page - 1) : null}>
          <ChevronLeft aria-hidden="true" className="size-4" /> Anterior
        </Step>
        <Step href={page < pages ? hrefFor(page + 1) : null}>
          Siguiente <ChevronRight aria-hidden="true" className="size-4" />
        </Step>
      </div>
    </nav>
  );
}
