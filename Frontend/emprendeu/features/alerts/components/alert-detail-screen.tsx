import Link from "next/link";
import { notFound } from "next/navigation";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { getAlert } from "../server/queries";
import { AlertActions } from "./alert-actions";

const TYPE_LABEL: Record<string, string> = {
  inactividad: "Inactividad",
  sentimiento: "Caída de sentimiento",
  compromiso_vencido: "Compromiso vencido",
};

/** CU13 · Detalle de una alerta: emprendimiento, motivo, fecha y estado, con las acciones disponibles. */
export async function AlertDetailScreen({ alertId }: { alertId: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "seguimiento:consulta")) return <NoAccess section="Alertas" />;

  const alert = await getAlert(alertId);
  if (!alert) notFound();
  const state = alert.estado ?? "";
  const unresolved = state === "abierta" || state === "revisada";
  const canManage = hasPermission(user, "seguimiento:registro");
  const row = "flex flex-col gap-1 border-t border-[#eef2fa] py-3.5 sm:flex-row sm:gap-6";
  const label = "text-[13px] font-bold tracking-[.06em] text-muted-foreground uppercase sm:w-44 sm:shrink-0";

  return (
    <>
      <PageHeader title={alert.titulo} subtitle="Detalle de la alerta de seguimiento." />
      <Link href="/alerts" className="mb-5 inline-flex min-h-11 items-center text-sm font-semibold text-primary">
        ← Volver a alertas
      </Link>
      <section aria-label="Detalle" className="rounded-2xl border border-border bg-card px-6 py-2">
        <div className={`${row} border-t-0`}>
          <div className={label}>Emprendimiento</div>
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1">
            <span className="font-semibold">{alert.emprendimiento ?? `#${alert.emprendimiento_id}`}</span>
            {hasPermission(user, "seguimiento:consulta") && (
              <>
                <Link href={`/ventures/${alert.emprendimiento_id}/history`} className="text-sm font-semibold text-primary hover:underline">
                  Ver historial
                </Link>
                <Link href={`/ventures/${alert.emprendimiento_id}/progress`} className="text-sm font-semibold text-primary hover:underline">
                  Ver progreso
                </Link>
              </>
            )}
          </div>
        </div>
        <div className={row}>
          <div className={label}>Motivo</div>
          <div>
            <div className="font-semibold">{TYPE_LABEL[alert.tipo ?? ""] ?? alert.tipo ?? "—"}</div>
            {alert.descripcion && <p className="mt-1 text-sm leading-normal text-muted-foreground">{alert.descripcion}</p>}
          </div>
        </div>
        <div className={row}>
          <div className={label}>Prioridad</div>
          <div className="font-semibold capitalize">{alert.prioridad ?? "—"}</div>
        </div>
        <div className={row}>
          <div className={label}>Detectada</div>
          <div>{alert.fecha_generacion ? formatDateTime(alert.fecha_generacion) : "—"}</div>
        </div>
        <div className={row}>
          <div className={label}>Estado</div>
          <div>
            <span className="font-semibold capitalize">{state || "—"}</span>
            {alert.atendida_por && <span className="text-muted-foreground"> · por {alert.atendida_por}</span>}
          </div>
        </div>
      </section>
      {canManage && unresolved && (
        <div className="mt-5 flex justify-end">
          <AlertActions alert={alert} />
        </div>
      )}
    </>
  );
}
