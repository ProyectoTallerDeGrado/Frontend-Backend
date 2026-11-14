import Link from "next/link";
import { ChevronRight, HeartPulse } from "lucide-react";

import type { HealthReport } from "../types";
import { HealthPill } from "./health-level";

/** Tarjeta del Resumen: los emprendimientos que necesitan atención (rojo y ámbar). */
export function HealthAttentionCard({ report }: { report: HealthReport }) {
  const urgent = report.emprendimientos.filter((r) => r.nivel !== "verde").slice(0, 5);
  return (
    <section className="rounded-2xl border border-border bg-card p-6" aria-labelledby="attention-title">
      <div className="flex items-center justify-between gap-3">
        <h2 id="attention-title" className="flex items-center gap-2 font-heading text-lg font-semibold">
          <HeartPulse className="size-5 text-primary" aria-hidden /> Necesitan atención
        </h2>
        <Link href="/health" className="flex items-center gap-1 text-sm font-semibold text-primary hover:underline">
          Ver todos <ChevronRight className="size-4" aria-hidden />
        </Link>
      </div>
      {urgent.length === 0 ? (
        <p className="mt-3 text-sm text-muted-foreground">Ningún emprendimiento muestra señales de riesgo.</p>
      ) : (
        <ul className="mt-3 divide-y divide-muted">
          {urgent.map((r) => (
            <li key={r.emprendimiento_id} className="flex flex-wrap items-center justify-between gap-2 py-2.5">
              <div className="min-w-0">
                <Link href={`/ventures/${r.emprendimiento_id}`} className="font-semibold hover:underline">
                  {r.nombre}
                </Link>
                <div className="text-[13px] text-muted-foreground">{r.motivos.join(" · ")}</div>
              </div>
              <HealthPill level={r.nivel} />
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
