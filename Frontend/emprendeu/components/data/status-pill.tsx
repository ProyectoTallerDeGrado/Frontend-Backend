import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

export type PillTone = "info" | "success" | "danger" | "warning" | "neutral" | "dark";

const TONES: Record<PillTone, string> = {
  info: "bg-blue-50 text-info-foreground",
  success: "bg-success-tint text-success-foreground",
  danger: "bg-danger-tint text-danger-foreground",
  warning: "bg-warning-tint text-warning-foreground",
  neutral: "bg-muted text-muted-foreground",
  dark: "bg-navy-900 text-white",
};

const DOTS: Record<PillTone, string> = {
  info: "bg-primary",
  success: "bg-success",
  danger: "bg-destructive",
  warning: "bg-gold",
  neutral: "bg-switch-off",
  dark: "bg-accent-bright",
};

/** Píldora de estado. Siempre lleva texto: el color nunca es la única señal. */
export function StatusPill({
  tone = "neutral",
  dot = false,
  className,
  children,
}: {
  tone?: PillTone;
  dot?: boolean;
  className?: string;
  children: ReactNode;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-[13px] font-bold whitespace-nowrap",
        TONES[tone],
        className,
      )}
    >
      {dot && <span aria-hidden="true" className={cn("size-1.5 rounded-full", DOTS[tone])} />}
      {children}
    </span>
  );
}
