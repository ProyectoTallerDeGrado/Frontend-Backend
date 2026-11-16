import { cn } from "@/lib/utils";

/** Pieza de carga con brillo (`.skeleton` en globals.css). Decorativa: el contenedor anuncia «Cargando». */
export function Skeleton({ className }: { className?: string }) {
  return <div aria-hidden="true" className={cn("skeleton rounded-lg", className)} />;
}

function HeaderSkeleton() {
  return (
    <div className="mb-7 flex flex-col gap-3">
      <Skeleton className="h-9 w-72 max-w-full" />
      <Skeleton className="h-5 w-[440px] max-w-full" />
    </div>
  );
}

/** Lista con buscador y tabla: la forma de casi todas las páginas del panel. */
function TableSkeleton() {
  return (
    <>
      <Skeleton className="mb-5 h-12 w-full max-w-[460px] rounded-xl" />
      <div className="overflow-hidden rounded-2xl border border-border bg-card">
        <div className="h-12 border-b border-border bg-surface-head" />
        {Array.from({ length: 6 }, (_, i) => (
          <div key={i} className="flex items-center gap-6 border-t border-muted px-5 py-4 first:border-t-0">
            <Skeleton className="h-4 flex-[2]" />
            <Skeleton className="hidden h-4 flex-1 sm:block" />
            <Skeleton className="hidden h-4 flex-1 md:block" />
            <Skeleton className="h-7 w-20 rounded-full" />
          </div>
        ))}
      </div>
    </>
  );
}

/** Indicadores arriba y dos paneles debajo: Resumen y Dashboard. */
function KpisSkeleton() {
  return (
    <>
      <div className="mb-6 grid grid-cols-[repeat(auto-fit,minmax(min(220px,100%),1fr))] gap-4">
        {Array.from({ length: 4 }, (_, i) => (
          <div key={i} className="rounded-2xl border border-border bg-card p-6">
            <Skeleton className="h-4 w-28" />
            <Skeleton className="mt-4 h-9 w-20" />
            <Skeleton className="mt-3 h-3.5 w-36" />
          </div>
        ))}
      </div>
      <div className="flex flex-wrap gap-6">
        <Skeleton className="h-64 min-w-[300px] flex-[1_1_420px] rounded-2xl" />
        <Skeleton className="h-64 min-w-[300px] flex-[1_1_320px] rounded-2xl" />
      </div>
    </>
  );
}

/** Pestaña de una ficha: título de sección y un bloque de contenido. */
function SectionSkeleton() {
  return (
    <>
      <Skeleton className="mb-4 h-6 w-48" />
      <Skeleton className="h-56 rounded-2xl" />
    </>
  );
}

/** Esqueleto de una página del panel con la forma del contenido que viene. */
export function PageSkeleton({ variant = "table" }: { variant?: "table" | "kpis" | "section" }) {
  return (
    <div role="status" aria-label="Cargando">
      {variant !== "section" && <HeaderSkeleton />}
      {variant === "table" && <TableSkeleton />}
      {variant === "kpis" && <KpisSkeleton />}
      {variant === "section" && <SectionSkeleton />}
    </div>
  );
}
