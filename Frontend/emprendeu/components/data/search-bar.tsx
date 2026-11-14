import Link from "next/link";
import { Search } from "lucide-react";
import type { ReactNode } from "react";

type SearchBarProps = {
  /** Ruta a la que se envía el formulario GET. */
  action: string;
  /** Valor actual de `q`. */
  q: string;
  label?: string;
  placeholder: string;
  /** URL sin búsqueda (conserva los demás filtros). */
  clearHref: string;
  /** Campos ocultos para conservar otros filtros al buscar. */
  hidden?: Record<string, string | undefined>;
  /** Filtros extra a la derecha (píldoras, selects). */
  children?: ReactNode;
};

/** Buscador de listas: formulario GET (navegable y funciona sin JavaScript). */
export function SearchBar({ action, q, label = "Buscar", placeholder, clearHref, hidden, children }: SearchBarProps) {
  return (
    <div className="mb-5 flex flex-wrap items-end gap-3">
      <form method="get" action={action} role="search" className="flex flex-[1_1_320px] flex-wrap items-end gap-3">
        {hidden &&
          Object.entries(hidden).map(([name, value]) =>
            value ? <input key={name} type="hidden" name={name} value={value} /> : null,
          )}
        <label className="flex min-w-[220px] max-w-[460px] flex-1 flex-col gap-1.5 text-[13px] font-semibold">
          {label}
          <span className="relative">
            <Search
              aria-hidden="true"
              className="pointer-events-none absolute top-1/2 left-4 size-[18px] -translate-y-1/2 text-muted-foreground"
            />
            <input
              type="search"
              name="q"
              defaultValue={q}
              placeholder={placeholder}
              className="h-12 w-full rounded-xl border-[1.5px] border-border-strong bg-card pr-4 pl-11 text-[15px] font-normal outline-none transition-[border-color,box-shadow] focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15"
            />
          </span>
        </label>
        <button
          type="submit"
          className="h-12 rounded-xl border-[1.5px] border-border-strong bg-card px-5 text-sm font-semibold outline-none transition-colors hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
        >
          Buscar
        </button>
        {q && (
          <Link
            href={clearHref}
            className="inline-flex min-h-12 items-center px-2 text-sm font-semibold text-primary hover:underline"
          >
            Quitar búsqueda
          </Link>
        )}
      </form>
      {children && <div className="flex flex-wrap items-center gap-2">{children}</div>}
    </div>
  );
}
