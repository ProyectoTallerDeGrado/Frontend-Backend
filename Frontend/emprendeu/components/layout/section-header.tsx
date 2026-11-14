import type { ReactNode } from "react";

/** Encabezado de una sección dentro de una página (h2), con acciones opcionales a la derecha. */
export function SectionHeader({
  id,
  title,
  subtitle,
  actions,
}: {
  id?: string;
  title: string;
  subtitle?: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <div className="mb-4 flex flex-wrap items-end justify-between gap-x-6 gap-y-3">
      <div className="min-w-0 flex-[1_1_360px]">
        <h2 id={id} className="font-heading text-lg font-semibold tracking-[-.01em]">
          {title}
        </h2>
        {subtitle && <p className="mt-1 max-w-[680px] text-sm leading-normal text-muted-foreground">{subtitle}</p>}
      </div>
      {actions && <div className="flex flex-wrap items-center gap-3">{actions}</div>}
    </div>
  );
}
