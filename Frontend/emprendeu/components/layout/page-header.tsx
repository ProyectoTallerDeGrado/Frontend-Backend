import type { ReactNode } from "react";

type PageHeaderProps = { title: string; subtitle: string; actions?: ReactNode };

export function PageHeader({ title, subtitle, actions }: PageHeaderProps) {
  return (
    <header className="mb-7 flex animate-[fade-up_.5s_ease_both] flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="mb-1.5 font-heading text-[30px] font-bold tracking-[-.02em]">{title}</h1>
        <p className="max-w-[680px] text-base leading-normal text-muted-foreground">{subtitle}</p>
      </div>
      {actions && <div className="flex items-center gap-3">{actions}</div>}
    </header>
  );
}
