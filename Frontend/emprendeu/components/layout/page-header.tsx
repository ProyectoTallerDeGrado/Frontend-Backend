import Link from "next/link";
import type { ReactNode } from "react";
import { ChevronLeft } from "lucide-react";

type PageHeaderProps = {
  title: string;
  subtitle?: ReactNode;
  actions?: ReactNode;
  /** Enlace de vuelta a la lista (pantallas de detalle). */
  back?: { href: string; label: string };
  /** Datos breves bajo el título (estado, fechas). */
  meta?: ReactNode;
};

export function PageHeader({ title, subtitle, actions, back, meta }: PageHeaderProps) {
  return (
    <header className="mb-7 flex flex-col gap-4">
      {back && (
        <Link
          href={back.href}
          transitionTypes={["nav-back"]}
          className="-ml-1 inline-flex min-h-11 w-fit items-center gap-1 rounded-lg pr-2 text-sm font-semibold text-muted-foreground outline-none transition-colors hover:text-primary focus-visible:ring-3 focus-visible:ring-primary/30"
        >
          <ChevronLeft aria-hidden="true" className="size-4" />
          {back.label}
        </Link>
      )}
      <div className="flex flex-wrap items-end justify-between gap-x-6 gap-y-4">
        <div className="min-w-0 flex-[1_1_420px]">
          <h1 className="font-heading text-[26px] leading-tight font-bold tracking-[-.02em] text-balance sm:text-[30px]">
            {title}
          </h1>
          {subtitle && (
            <p className="mt-1.5 max-w-[680px] text-base leading-normal text-pretty text-muted-foreground">{subtitle}</p>
          )}
          {meta && <div className="mt-3 flex flex-wrap items-center gap-2">{meta}</div>}
        </div>
        {actions && <div className="flex flex-wrap items-center gap-3">{actions}</div>}
      </div>
    </header>
  );
}
