import Link from "next/link";

import { cn } from "@/lib/utils";

export type FilterOption = { label: string; href: string; active: boolean; count?: number };

/** Filtros-píldora navegables (cada opción es un enlace con `aria-current`). */
export function FilterPills({ label, options }: { label: string; options: FilterOption[] }) {
  return (
    <nav aria-label={label} className="flex flex-wrap gap-2">
      {options.map((option) => (
        <Link
          key={option.href}
          href={option.href}
          aria-current={option.active ? "true" : undefined}
          className={cn(
            "inline-flex min-h-11 items-center gap-2 rounded-full border-[1.5px] px-4 text-sm font-semibold outline-none transition-[background,color,border-color] duration-200 focus-visible:ring-3 focus-visible:ring-primary/30",
            option.active
              ? "border-navy-900 bg-navy-900 text-white"
              : "border-border-strong bg-card text-foreground hover:border-primary/40 hover:bg-blue-50",
          )}
        >
          {option.label}
          {option.count !== undefined && (
            <span
              className={cn(
                "rounded-full px-1.5 text-[12px] font-bold",
                option.active ? "bg-white/15" : "bg-muted text-muted-foreground",
              )}
            >
              {option.count}
            </span>
          )}
        </Link>
      ))}
    </nav>
  );
}
