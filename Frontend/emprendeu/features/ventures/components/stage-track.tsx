import { Check } from "lucide-react";

import { cn } from "@/lib/utils";

import { orderedStages } from "../stages";
import type { Stage } from "../types";

/**
 * Trayecto del emprendimiento por las etapas del programa (motivo de órbitas de la marca):
 * la línea crece hasta la etapa actual y los nodos se encienden uno tras otro.
 */
export function StageTrack({ stages, current }: { stages: Stage[]; current: Stage | null }) {
  const steps = orderedStages(stages);
  if (steps.length === 0) return null;
  const currentIndex = current ? steps.findIndex((s) => s.etapa_id === current.etapa_id) : -1;
  // Fracción de la línea que se pinta: del primer nodo al actual.
  const fill = steps.length > 1 && currentIndex > 0 ? currentIndex / (steps.length - 1) : 0;
  const nodeDelay = (i: number) => `${180 + i * 140}ms`;

  return (
    <div className="relative overflow-x-auto pb-1">
      <ol
        aria-label="Etapas del programa"
        className="relative grid min-w-[520px] items-start"
        style={{ gridTemplateColumns: `repeat(${steps.length}, minmax(0, 1fr))` }}
      >
        {/* Pista y relleno: van del centro del primer nodo al centro del último. */}
        <span
          aria-hidden="true"
          className="absolute top-[17px] h-1 rounded-full bg-muted"
          style={{ left: `${50 / steps.length}%`, right: `${50 / steps.length}%` }}
        />
        <span
          aria-hidden="true"
          className="absolute top-[17px] h-1 origin-left animate-[grow-x_1s_cubic-bezier(.2,.8,.2,1)_.15s_both] rounded-full bg-primary"
          style={{
            left: `${50 / steps.length}%`,
            width: `calc(${fill} * (100% - ${100 / steps.length}%))`,
          }}
        />
        {steps.map((step, i) => {
          const state = i < currentIndex ? "done" : i === currentIndex ? "current" : "pending";
          return (
            <li
              key={step.etapa_id}
              aria-current={state === "current" ? "step" : undefined}
              className="relative flex flex-col items-center gap-2 px-2 text-center"
            >
              <span
                className={cn(
                  "relative z-10 flex size-9 animate-[node-pop_.5s_cubic-bezier(.3,1.4,.5,1)_both] items-center justify-center rounded-full font-heading text-sm font-bold ring-4 ring-background",
                  state === "done" && "bg-primary text-white",
                  state === "current" && "bg-navy-900 text-white",
                  state === "pending" && "border-2 border-border-strong bg-card text-muted-foreground",
                )}
                style={{ animationDelay: nodeDelay(i) }}
              >
                {state === "current" && (
                  <span
                    aria-hidden="true"
                    className="absolute inset-0 animate-[halo_2.4s_ease-out_1.2s_infinite] rounded-full"
                  />
                )}
                {state === "done" ? <Check aria-hidden="true" className="size-4" strokeWidth={3} /> : i + 1}
              </span>
              <span
                className={cn(
                  "text-[13px] leading-snug",
                  state === "current" ? "font-bold text-foreground" : "font-medium text-muted-foreground",
                )}
              >
                {step.nombre}
                <span className="sr-only">
                  {state === "done" ? " (completada)" : state === "current" ? " (etapa actual)" : " (pendiente)"}
                </span>
              </span>
            </li>
          );
        })}
      </ol>
    </div>
  );
}
