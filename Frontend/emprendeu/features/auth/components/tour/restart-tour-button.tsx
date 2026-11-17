"use client";

import { Compass } from "lucide-react";

import { cn } from "@/lib/utils";

import { useTourStore } from "../../stores/tour-store";

/** Vuelve a mostrar el tutorial guiado (en el chat de ayuda y en «Mi cuenta»). */
export function RestartTourButton({ className }: { className?: string }) {
  const start = useTourStore((s) => s.start);
  return (
    <button
      type="button"
      onClick={start}
      className={cn(
        "inline-flex min-h-9 items-center gap-2 rounded-xl px-3 text-[13px] font-semibold text-primary outline-none transition-colors hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-ring/40",
        className,
      )}
    >
      <Compass aria-hidden="true" className="size-4" />
      Ver el tutorial del sistema
    </button>
  );
}
