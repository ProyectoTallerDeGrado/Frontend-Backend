import Link from "next/link";
import { notFound } from "next/navigation";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { getAdmission } from "../server/queries";
import { AdmissionDecisionForm } from "./admission-decision-form";

/** CU26 · Información del postulante y de su emprendimiento, con la decisión. */
export async function AdmissionDetailScreen({ id }: { id: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "emprendedores:consulta")) return <NoAccess section="Admisiones" />;

  const a = await getAdmission(id);
  if (!a) notFound();
  const canDecide = hasPermission(user, "emprendedores:registro");
  const row = "flex flex-col gap-1 border-t border-[#eef2fa] py-3.5 sm:flex-row sm:gap-6";
  const label = "text-[13px] font-bold tracking-[.06em] text-muted-foreground uppercase sm:w-44 sm:shrink-0";
  const applicant = `${a.nombre} ${a.apellido}`;

  return (
    <>
      <PageHeader title={applicant} subtitle={`Postulación con el emprendimiento «${a.nombre_emprendimiento}».`} />
      <Link href="/admissions" className="mb-5 inline-flex min-h-11 items-center text-sm font-semibold text-primary">
        ← Volver a admisiones
      </Link>
      <div className="flex flex-wrap items-start gap-6">
        <section aria-label="Datos de la postulación" className="min-w-[300px] flex-[1_1_480px] rounded-2xl border border-border bg-card px-6 py-2">
          <div className={`${row} border-t-0`}><div className={label}>Correo</div><div>{a.email}</div></div>
          <div className={row}><div className={label}>Teléfono</div><div>{a.telefono ?? "—"}</div></div>
          <div className={row}><div className={label}>Documento</div><div>{a.documento_identidad ?? "No indicado"}</div></div>
          <div className={row}><div className={label}>Emprendimiento</div><div className="font-semibold">{a.nombre_emprendimiento}</div></div>
          <div className={row}><div className={label}>Sector</div><div>{a.sector ?? "—"}</div></div>
          <div className={row}>
            <div className={label}>Descripción</div>
            <p className="text-sm leading-normal">{a.descripcion_emprendimiento ?? "Sin descripción."}</p>
          </div>
          <div className={row}><div className={label}>Postuló</div><div>{formatDateTime(a.fecha_postulacion)}</div></div>
          <div className={row}>
            <div className={label}>Estado</div>
            <div className="font-semibold capitalize">
              {a.estado}
              {a.fecha_decision && <span className="font-normal text-muted-foreground"> · {formatDateTime(a.fecha_decision)}</span>}
            </div>
          </div>
          {a.observaciones_decision && (
            <div className={row}><div className={label}>Observaciones</div><p className="text-sm leading-normal">{a.observaciones_decision}</p></div>
          )}
          {a.emprendimiento_id && (
            <div className={row}>
              <div className={label}>Emprendimiento creado</div>
              <Link href={`/ventures/${a.emprendimiento_id}/history`} className="text-sm font-semibold text-primary hover:underline">
                Ver historial
              </Link>
            </div>
          )}
        </section>
        <aside className="min-w-[300px] flex-[1_1_360px] rounded-2xl border border-border bg-card p-6">
          <h2 className="mb-4 font-heading text-lg font-semibold">Decisión</h2>
          {a.estado !== "pendiente" ? (
            <p className="rounded-xl bg-muted px-4 py-3 text-sm text-muted-foreground">
              Esta postulación ya tiene una decisión definitiva: <strong className="capitalize">{a.estado}</strong>.
            </p>
          ) : canDecide ? (
            <AdmissionDecisionForm id={a.postulacion_id} applicant={applicant} hasDocument={Boolean(a.documento_identidad)} />
          ) : (
            <p className="rounded-xl bg-muted px-4 py-3 text-sm text-muted-foreground">Tu rol puede consultar las postulaciones, pero no decidirlas.</p>
          )}
        </aside>
      </div>
    </>
  );
}
