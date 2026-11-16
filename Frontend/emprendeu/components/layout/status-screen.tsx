import type { ReactNode } from "react";

/**
 * Pantalla de estado a página completa (no encontrada, error): fondo de marca, un mensaje y qué
 * se puede hacer. Sin negocio: la usan las convenciones `not-found` y `error` de `app/`.
 */
export function StatusScreen({
  code,
  title,
  description,
  children,
}: {
  code: string;
  title: string;
  description: string;
  children: ReactNode;
}) {
  return (
    <main className="relative isolate flex min-h-screen flex-col items-center justify-center overflow-hidden bg-navy-950 px-6 py-16 text-center text-white">
      <svg
        aria-hidden="true"
        viewBox="0 0 600 600"
        className="pointer-events-none absolute top-1/2 left-1/2 -z-10 size-[min(900px,160vw)] -translate-x-1/2 -translate-y-1/2 text-on-navy-dim opacity-50"
      >
        <circle cx="300" cy="300" r="270" fill="none" stroke="currentColor" strokeOpacity=".25" strokeWidth="1.5" />
        <circle cx="300" cy="300" r="180" fill="none" stroke="currentColor" strokeOpacity=".35" strokeWidth="1.5" strokeDasharray="4 9" />
        <circle cx="300" cy="30" r="7" fill="var(--accent-bright)" />
      </svg>
      <p className="font-heading text-sm font-bold tracking-[.2em] text-accent-bright uppercase">{code}</p>
      <h1 className="mt-4 max-w-[18ch] font-heading text-[clamp(32px,6vw,56px)] leading-[1.05] font-bold tracking-[-.03em] text-balance">
        {title}
      </h1>
      <p className="mt-5 max-w-[46ch] text-lg leading-relaxed text-on-navy-muted">{description}</p>
      <div className="mt-9 flex flex-wrap items-center justify-center gap-3">{children}</div>
    </main>
  );
}

/** Clases de los dos botones de `StatusScreen` (enlace o `<button>`). */
export const statusAction = {
  primary:
    "inline-flex min-h-12 items-center rounded-xl bg-accent-bright px-6 text-base font-bold text-on-accent outline-none transition-transform duration-200 hover:-translate-y-0.5 focus-visible:ring-4 focus-visible:ring-white/50",
  ghost:
    "inline-flex min-h-12 items-center rounded-xl px-5 text-base font-semibold text-white outline-none transition-colors hover:bg-white/10 focus-visible:ring-4 focus-visible:ring-white/40",
} as const;
