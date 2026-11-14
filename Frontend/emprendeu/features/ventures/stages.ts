import type { Stage } from "./types";

/** Etapas activas del programa en su orden. */
export function orderedStages(stages: Stage[]): Stage[] {
  return stages.filter((s) => s.estado === "activa").sort((a, b) => (a.orden ?? 0) - (b.orden ?? 0));
}

/** Etapa activa inmediatamente siguiente a `current` (la misma regla que aplica el backend). */
export function nextStage(stages: Stage[], current: Stage | null): Stage | null {
  const active = orderedStages(stages);
  if (!current) return active[0] ?? null;
  return active.find((s) => (s.orden ?? 0) > (current.orden ?? 0)) ?? null;
}
