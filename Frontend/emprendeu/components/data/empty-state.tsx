import type { LucideIcon } from "lucide-react";
import type { ReactNode } from "react";

/** Pantalla o tarjeta vacía: qué falta y qué se puede hacer. */
export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
}: {
  icon: LucideIcon;
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-border-strong bg-card px-6 py-12 text-center">
      <span className="flex size-14 items-center justify-center rounded-2xl bg-blue-50 text-primary">
        <Icon aria-hidden="true" className="size-7" />
      </span>
      <h2 className="font-heading text-lg font-semibold">{title}</h2>
      {description && <p className="max-w-md text-[15px] leading-normal text-muted-foreground">{description}</p>}
      {action && <div className="mt-1">{action}</div>}
    </div>
  );
}
