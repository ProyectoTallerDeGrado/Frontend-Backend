import { Rocket } from "lucide-react";

import { EmptyState } from "@/components/data/empty-state";
import { StatusPill } from "@/components/data/status-pill";
import { NoAccess } from "@/components/layout/no-access";
import { SectionHeader } from "@/components/layout/section-header";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";
import { cn } from "@/lib/utils";

import { getStageHistory } from "../server/queries";

/** CU12 · Recorrido del emprendimiento por las etapas: cuándo entró, cuándo salió y por qué. */
export async function StageHistoryScreen({ ventureId }: { ventureId: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "seguimiento:consulta")) return <NoAccess section="Historial de etapas" />;

  const steps = await getStageHistory(ventureId);
  return (
    <>
      <SectionHeader
        title="Cambios de etapa"
        subtitle="Cada cambio de etapa conserva la anterior, con su fecha y la observación de quien lo registró."
      />
      {steps.length === 0 ? (
        <EmptyState
          icon={Rocket}
          title="Todavía sin etapa"
          description="Asigna la primera etapa con «Pasar a…» en la cabecera para empezar su recorrido."
        />
      ) : (
        <ol className="relative flex flex-col gap-4 pl-8 before:absolute before:top-3 before:bottom-3 before:left-[11px] before:w-0.5 before:rounded-full before:bg-border">
          {steps.map((s) => {
            const current = s.estado === "activa";
            return (
              <li key={s.emprendimiento_etapa_id} className="relative">
                <span
                  aria-hidden="true"
                  className={cn(
                    "absolute top-4 -left-8 size-6 rounded-full ring-4 ring-background",
                    current ? "bg-navy-900" : "bg-primary",
                  )}
                />
                <div className="rounded-2xl border border-border bg-card px-5 py-4">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <span className="font-heading text-base font-semibold">{s.etapa}</span>
                    <StatusPill tone={current ? "dark" : "success"} dot={current} className="capitalize">
                      {current ? "Actual" : (s.estado ?? "—")}
                    </StatusPill>
                  </div>
                  <p className="mt-1 text-[13px] text-muted-foreground">
                    {s.fecha_inicio ? `Desde ${formatDateTime(s.fecha_inicio)}` : "Sin fecha de inicio"}
                    {s.fecha_fin ? ` hasta ${formatDateTime(s.fecha_fin)}` : ""}
                  </p>
                  {s.observaciones && <p className="mt-2 text-sm leading-normal">{s.observaciones}</p>}
                </div>
              </li>
            );
          })}
        </ol>
      )}
    </>
  );
}
