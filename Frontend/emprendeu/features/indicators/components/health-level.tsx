import type { VentureHealth } from "../types";

/** Semáforo: color y texto (el color nunca va solo, por accesibilidad). */
export const LEVEL: Record<VentureHealth["nivel"], { label: string; pill: string; bar: string }> = {
  rojo: { label: "Atender ya", pill: "bg-danger-tint text-danger-foreground", bar: "bg-danger-foreground" },
  ambar: { label: "Vigilar", pill: "bg-warning-tint text-warning-foreground", bar: "bg-warning-foreground" },
  verde: { label: "Bien", pill: "bg-success-tint text-success-foreground", bar: "bg-success-foreground" },
};

export function HealthPill({ level }: { level: VentureHealth["nivel"] }) {
  const meta = LEVEL[level];
  return <span className={`rounded-full px-3 py-1 text-[13px] font-bold whitespace-nowrap ${meta.pill}`}>{meta.label}</span>;
}

export function ScoreBar({ score, level }: { score: number; level: VentureHealth["nivel"] }) {
  return (
    <div className="flex items-center gap-2">
      <div className="h-2 w-24 overflow-hidden rounded-full bg-muted" aria-hidden>
        <div className={`h-full rounded-full ${LEVEL[level].bar}`} style={{ width: `${score}%` }} />
      </div>
      <span className="font-heading text-sm font-semibold tabular-nums">{score}</span>
    </div>
  );
}
