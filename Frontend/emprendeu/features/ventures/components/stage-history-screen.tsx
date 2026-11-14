import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { getStageHistory } from "../server/queries";

type Props = { ventureId: number; ventureName: string };

/** CU12 · Recorrido del emprendimiento por las etapas: cuándo entró, cuándo salió y por qué. */
export async function StageHistoryScreen({ ventureId, ventureName }: Props) {
  const user = await requireSession();
  if (!hasPermission(user, "seguimiento:consulta")) return <NoAccess section="Historial de etapas" />;

  const steps = await getStageHistory(ventureId);
  return (
    <>
      <PageHeader
        title={`Etapas · ${ventureName}`}
        subtitle="Cada cambio de etapa conserva la anterior, con su fecha y la observación de quien lo registró."
      />
      <Link href="/ventures" className="mb-5 inline-flex min-h-11 items-center text-sm font-semibold text-primary">
        ← Volver a emprendimientos
      </Link>
      {steps.length === 0 ? (
        <p className="rounded-2xl border border-border bg-card p-8 text-center text-muted-foreground">
          Este emprendimiento todavía no tiene etapa asignada.
        </p>
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-border bg-card">
          <table className="w-full min-w-[720px] border-collapse text-left text-sm">
            <thead>
              <tr className="bg-[#f4f6fb] text-[12px] font-bold tracking-[.06em] text-muted-foreground uppercase">
                <th scope="col" className="px-5 py-3.5">Etapa</th>
                <th scope="col" className="px-5 py-3.5">Estado</th>
                <th scope="col" className="px-5 py-3.5">Desde</th>
                <th scope="col" className="px-5 py-3.5">Hasta</th>
                <th scope="col" className="px-5 py-3.5">Observaciones</th>
              </tr>
            </thead>
            <tbody>
              {steps.map((s) => (
                <tr key={s.emprendimiento_etapa_id} className="border-t border-[#eef2fa] align-top">
                  <td className="px-5 py-3.5 font-semibold">{s.etapa}</td>
                  <td className="px-5 py-3.5">
                    <span
                      className={`rounded-full px-3 py-1 text-[13px] font-bold capitalize ${s.estado === "activa" ? "bg-blue-50 text-primary" : "bg-success-tint text-success-foreground"}`}
                    >
                      {s.estado === "activa" ? "Actual" : (s.estado ?? "—")}
                    </span>
                  </td>
                  <td className="px-5 py-3.5 text-muted-foreground">{s.fecha_inicio ? formatDateTime(s.fecha_inicio) : "—"}</td>
                  <td className="px-5 py-3.5 text-muted-foreground">{s.fecha_fin ? formatDateTime(s.fecha_fin) : "—"}</td>
                  <td className="px-5 py-3.5 text-muted-foreground">{s.observaciones ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
