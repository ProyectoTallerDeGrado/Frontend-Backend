import Link from "next/link";
import type { ComponentProps, CSSProperties, ReactNode } from "react";

import { cn } from "@/lib/utils";

/**
 * Piezas comunes de la landing: botón, contenedor y títulos de sección. Viven en la feature porque
 * su forma (escala tipográfica grande, acento coral) es propia de la página pública, no del panel.
 */

const VARIANTS = {
  accent: "bg-accent-bright font-bold text-on-accent shadow-glow-accent hover:-translate-y-0.5 focus-visible:ring-white/50",
  primary: "bg-primary font-bold text-white hover:-translate-y-0.5 hover:bg-primary-hover focus-visible:ring-primary/30",
  ghost: "font-semibold text-white hover:bg-white/10 focus-visible:ring-white/40",
} as const;

const SIZES = {
  sm: "min-h-11 px-4 text-[15px]",
  md: "min-h-14 px-7 text-base",
  lg: "min-h-16 px-9 text-lg",
} as const;

type LandingButtonProps = ComponentProps<typeof Link> & {
  variant?: keyof typeof VARIANTS;
  size?: keyof typeof SIZES;
};

export function LandingButton({ variant = "accent", size = "md", className, ...props }: LandingButtonProps) {
  return (
    <Link
      className={cn(
        "inline-flex items-center gap-2 rounded-xl outline-none transition-[transform,background-color] duration-200 focus-visible:ring-4",
        VARIANTS[variant],
        SIZES[size],
        className,
      )}
      {...props}
    />
  );
}

export function Container({ className, children }: { className?: string; children: ReactNode }) {
  return <div className={cn("mx-auto w-full max-w-[1240px] px-5 sm:px-8", className)}>{children}</div>;
}

const HEADING_SIZES = {
  lg: "text-[clamp(36px,5vw,64px)] leading-[1.02]",
  md: "text-[clamp(30px,4vw,52px)] leading-[1.04]",
} as const;

export function SectionHeading({
  id,
  size = "lg",
  className,
  children,
}: {
  id: string;
  size?: keyof typeof HEADING_SIZES;
  className?: string;
  children: ReactNode;
}) {
  return (
    <h2 id={id} className={cn("max-w-[16ch] font-heading font-bold tracking-[-.03em] text-balance", HEADING_SIZES[size], className)}>
      {children}
    </h2>
  );
}

export function SectionLead({ className, children }: { className?: string; children: ReactNode }) {
  return <p className={cn("mt-5 max-w-[56ch] text-lg leading-relaxed text-muted-foreground", className)}>{children}</p>;
}

/** Retraso de la entrada CSS (`.landing-rise`, `.landing-pop`). */
export const delay = (ms: number) => ({ "--delay": `${ms}ms` }) as CSSProperties;
