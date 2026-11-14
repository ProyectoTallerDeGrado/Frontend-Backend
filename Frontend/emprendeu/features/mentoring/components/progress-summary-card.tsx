import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { getProgressSummary } from "../server/queries";

/** CU20 · Progreso derivado del emprendimiento: hitos cumplidos y último avance reportado. */
export async function ProgressSummaryCard({ ventureId }: { ventureId: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "seguimiento:consulta")) return null;
  const s = await getProgressSummary(ventureId);
  return (
    <section aria-label="Progreso del emprendimiento" className="mb-6 rounded-2xl border border-border bg-card p-5">
      <div className="flex items-baseline justify-between gap-4">
        <h2 className="font-heading text-lg font-semibold">Progreso del emprendimiento</h2>
        <span className="text-2xl font-bold text-primary">{s.porcentaje}%</span>
      </div>
      <div
        role="progressbar"
        aria-valuenow={s.porcentaje}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label="Progreso"
        className="mt-3 h-3 overflow-hidden rounded-full bg-blue-50"
      >
        <div className="h-full rounded-full bg-primary" style={{ width: `${s.porcentaje}%` }} />
      </div>
      <p className="mt-3 text-sm text-muted-foreground">
        {s.hitos_total > 0
          ? `${s.hitos_cumplidos} de ${s.hitos_total} hitos cumplidos.`
          : "Sin hitos registrados: se muestra el último avance reportado."}
        {s.ultimo_avance !== null && (
          <>
            {" "}
            Último avance reportado: {s.ultimo_avance}%
            {s.fecha_ultimo_avance ? ` (${formatDateTime(s.fecha_ultimo_avance)})` : ""}.
          </>
        )}
      </p>
    </section>
  );
}
