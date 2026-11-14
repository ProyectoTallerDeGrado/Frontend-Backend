import type { ReactNode, ThHTMLAttributes, TdHTMLAttributes, HTMLAttributes } from "react";

import { cn } from "@/lib/utils";

/**
 * Tabla del panel: tarjeta con scroll horizontal propio (la página nunca hace scroll lateral),
 * cabecera en `surface-head` y filas con hover. Solo presentación, sin datos.
 */
export function DataTable({
  minWidth = 880,
  caption,
  className,
  children,
}: {
  /** Ancho mínimo interno en px antes de que aparezca el scroll horizontal de la tarjeta. */
  minWidth?: number;
  /** Descripción para lectores de pantalla. */
  caption?: string;
  className?: string;
  children: ReactNode;
}) {
  return (
    <div className={cn("relative overflow-x-auto rounded-2xl border border-border bg-card", className)}>
      <table className="w-full border-collapse text-left text-sm" style={{ minWidth }}>
        {caption && <caption className="sr-only">{caption}</caption>}
        {children}
      </table>
    </div>
  );
}

export function THead({ children }: { children: ReactNode }) {
  return (
    <thead>
      <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
        {children}
      </tr>
    </thead>
  );
}

export function Th({ className, children, ...props }: ThHTMLAttributes<HTMLTableCellElement>) {
  return (
    <th scope="col" className={cn("px-5 py-3.5 font-semibold whitespace-nowrap", className)} {...props}>
      {children}
    </th>
  );
}

export function Tr({
  className,
  highlight,
  children,
  ...props
}: HTMLAttributes<HTMLTableRowElement> & { highlight?: boolean }) {
  return (
    <tr
      className={cn(
        "border-t border-muted align-middle transition-colors duration-150 first:border-t-0 hover:bg-row-hover",
        highlight && "animate-[flash_2.2s_ease-out_both]",
        className,
      )}
      {...props}
    >
      {children}
    </tr>
  );
}

export function Td({ className, children, ...props }: TdHTMLAttributes<HTMLTableCellElement>) {
  return (
    <td className={cn("px-5 py-3.5", className)} {...props}>
      {children}
    </td>
  );
}

/** Fila única para una tabla vacía: dice qué pasa y qué hacer. */
export function EmptyRow({ colSpan, children }: { colSpan: number; children: ReactNode }) {
  return (
    <tr>
      <td colSpan={colSpan} className="px-5 py-12 text-center text-[15px] text-muted-foreground">
        {children}
      </td>
    </tr>
  );
}

/** Enlace de acción dentro de una fila (alto mínimo de 44 px). */
export const rowLinkClass =
  "inline-flex min-h-11 items-center text-sm font-semibold text-primary underline-offset-4 outline-none hover:text-primary-hover hover:underline focus-visible:ring-3 focus-visible:ring-primary/30 rounded-md";
