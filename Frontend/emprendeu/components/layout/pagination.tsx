import Link from "next/link";
import { ChevronLeft, ChevronRight } from "lucide-react";

type PaginationProps = {
  page: number;
  pageSize: number;
  total: number;
  /** Construye la URL de una página (conserva los filtros). */
  hrefFor: (page: number) => string;
};

export function Pagination({ page, pageSize, total, hrefFor }: PaginationProps) {
  const pages = Math.max(1, Math.ceil(total / pageSize));
  if (pages <= 1) return null;
  const link =
    "inline-flex min-h-11 items-center gap-1 rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30";
  const disabled = "pointer-events-none opacity-45";
  return (
    <nav aria-label="Paginación" className="flex items-center justify-between gap-4 pt-2 text-sm">
      <span className="text-muted-foreground">
        Página {page} de {pages} · {total} registros
      </span>
      <div className="flex gap-2">
        <Link
          href={hrefFor(Math.max(1, page - 1))}
          aria-disabled={page <= 1}
          className={`${link} ${page <= 1 ? disabled : ""}`}
        >
          <ChevronLeft aria-hidden="true" className="size-4" /> Anterior
        </Link>
        <Link
          href={hrefFor(Math.min(pages, page + 1))}
          aria-disabled={page >= pages}
          className={`${link} ${page >= pages ? disabled : ""}`}
        >
          Siguiente <ChevronRight aria-hidden="true" className="size-4" />
        </Link>
      </div>
    </nav>
  );
}
