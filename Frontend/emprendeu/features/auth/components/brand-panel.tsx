import Image from "next/image";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import type { ReactNode } from "react";

type BrandPanelProps = {
  badge?: string;
  title?: string;
  text?: string;
  /** Contenido extra bajo el texto (p. ej. los pasos de la postulación). */
  children?: ReactNode;
  /** Lleva más contenido encima (pasos de la postulación): la órbita se atenúa y en pantallas chicas se quita. */
  compact?: boolean;
  /** Enlace de vuelta visible arriba del todo (p. ej. «Volver al inicio» en la postulación). */
  back?: { href: string; label: string };
};

/**
 * Panel de marca (izquierda): logo, mensaje y órbitas decorativas. Por defecto habla al personal
 * (login, registro); la postulación pública pasa su propio mensaje.
 */
export function BrandPanel({
  badge = "Panel del personal del CIE-U",
  title = "Seguimiento de emprendedores, bajo control.",
  text = "Admisiones, mentorías, alertas y el avance de cada emprendimiento por las etapas del programa, en un solo lugar.",
  children,
  compact = false,
  back,
}: BrandPanelProps) {
  return (
    <section
      className={`relative flex min-w-0 flex-[1_1_560px] flex-col justify-between overflow-hidden bg-navy-950 px-8 py-10 text-white sm:px-16 sm:py-14 gap-10 lg:min-h-[520px]`}
    >
      <svg
        aria-hidden="true"
        viewBox="0 0 600 600"
        fill="none"
        // Con más texto encima (variante compacta) la órbita se atenúa, y en pantallas chicas se quita.
        className={`pointer-events-none absolute -right-[180px] -bottom-[160px] size-[760px] ${
          compact ? "hidden opacity-40 lg:block" : "opacity-30 lg:opacity-90"
        }`}
      >
        <g
          style={{ transformOrigin: "300px 300px" }}
          className="animate-[orbit-spin_60s_linear_infinite]"
        >
          <circle cx="300" cy="300" r="120" stroke="var(--primary)" strokeOpacity=".55" strokeWidth="1.5" />
          <circle cx="420" cy="300" r="9" fill="var(--chart-3)" />
        </g>
        <g
          style={{ transformOrigin: "300px 300px" }}
          className="animate-[orbit-spin-reverse_90s_linear_infinite]"
        >
          <circle cx="300" cy="300" r="210" stroke="var(--primary-foreground)" strokeOpacity=".14" strokeWidth="1.5" strokeDasharray="4 10" />
          <circle cx="300" cy="90" r="7" fill="var(--primary-foreground)" />
        </g>
        <g
          style={{ transformOrigin: "300px 300px" }}
          className="animate-[orbit-spin_140s_linear_infinite]"
        >
          <circle cx="300" cy="300" r="290" stroke="var(--primary)" strokeOpacity=".3" strokeWidth="1.5" />
          <circle cx="506" cy="506" r="11" fill="var(--primary)" />
        </g>
        <circle
          cx="300"
          cy="300"
          r="56"
          fill="color-mix(in srgb, var(--primary) 45%, var(--navy-950))"
          style={{ transformOrigin: "300px 300px" }}
          className="animate-[core-pulse_4s_ease-in-out_infinite]"
        />
      </svg>

      <div className="relative flex flex-col gap-6">
        {back && (
          <Link
            href={back.href}
            className="-ml-2 inline-flex min-h-11 w-fit items-center gap-2 rounded-lg px-2 text-[15px] font-semibold text-on-navy-muted outline-none transition-colors hover:text-white focus-visible:ring-3 focus-visible:ring-white/50"
          >
            <ArrowLeft aria-hidden="true" className="size-4" />
            {back.label}
          </Link>
        )}
      <Link
        href="/"
        aria-label="Ir a la portada del CIE-U"
        className="relative flex w-fit items-center gap-3.5 rounded-2xl outline-none focus-visible:ring-3 focus-visible:ring-white/50"
      >
        <Image
          src="/brand/cie-u-logo.png"
          alt="Logo del CIE-U"
          width={56}
          height={56}
          priority
          className="size-14 rounded-[14px] object-cover ring-1 ring-white/20"
        />
        <div className="font-heading text-[15px] leading-[1.3] font-semibold tracking-[.01em]">
          Centro de Innovación y
          <br />
          Emprendimiento Universitario
        </div>
      </Link>
      </div>

      <div className="relative max-w-[560px]">
        <p className="text-[15px] font-semibold text-on-navy-muted">{badge}</p>
        <h1 className="mt-3 mb-4 animate-[fade-up_.7s_cubic-bezier(.2,.8,.2,1)_both] font-heading text-[34px] leading-[1.1] font-bold tracking-[-.02em] text-balance sm:text-[46px]">
          {title}
        </h1>
        <p className="max-w-[480px] text-[17px] leading-[1.55] text-on-navy-muted text-pretty">
          {text}
        </p>
        {children}
      </div>

      <div className="relative text-sm text-on-navy-faint">
        FCEE · UAGRM · Santa Cruz, Bolivia
      </div>
    </section>
  );
}
