import { NoAccess } from "@/components/layout/no-access";
import { SectionHeader } from "@/components/layout/section-header";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { listVentureCommitments, listVentureRecommendations } from "../server/queries";
import { CompleteCommitmentButton } from "./complete-commitment-button";
import { ProgressSummaryCard } from "./progress-summary-card";

type Props = { ventureId: number };

/** CU17 y CU18 · Recomendaciones y compromisos del emprendimiento, con su avance. */
export async function FollowUpScreen({ ventureId }: Props) {
  const user = await requireSession();
  if (!hasPermission(user, "seguimiento:consulta")) return <NoAccess section="Seguimiento" />;

  const [recommendations, commitments] = await Promise.all([
    listVentureRecommendations(ventureId),
    listVentureCommitments(ventureId),
  ]);
  const canUpdate = hasPermission(user, "asesorias:modificacion");
  const heading = "mb-3 font-heading text-lg font-semibold";

  return (
    <>
      <SectionHeader
        title="Seguimiento"
        subtitle="Recomendaciones del acompañamiento y compromisos con su responsable y fecha prevista."
      />
      <ProgressSummaryCard ventureId={ventureId} />

      <section aria-labelledby="commitments-title" className="mb-8">
        <h2 id="commitments-title" className={heading}>Compromisos</h2>
        {commitments.length === 0 ? (
          <p className="rounded-2xl border border-border bg-card p-6 text-center text-muted-foreground">Todavía no hay compromisos.</p>
        ) : (
          <div className="relative overflow-x-auto rounded-2xl border border-border bg-card">
            <table className="w-full min-w-[760px] border-collapse text-left text-sm">
              <thead>
                <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
                  <th scope="col" className="px-5 py-3.5">Compromiso</th>
                  <th scope="col" className="px-5 py-3.5">Responsable</th>
                  <th scope="col" className="px-5 py-3.5">Fecha prevista</th>
                  <th scope="col" className="px-5 py-3.5">Estado</th>
                  {canUpdate && <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>}
                </tr>
              </thead>
              <tbody>
                {commitments.map((c) => {
                  const done = c.estado === "cumplido";
                  const overdue = c.vencido;
                  return (
                    <tr key={c.compromiso_id} className="border-t border-muted transition-colors hover:bg-row-hover align-top">
                      <td className="max-w-[360px] px-5 py-3.5 font-semibold">{c.descripcion ?? "—"}</td>
                      <td className="px-5 py-3.5 text-muted-foreground">{c.responsable ?? "—"}</td>
                      <td className="px-5 py-3.5 text-muted-foreground">{c.fecha_limite ? formatDateTime(c.fecha_limite) : "—"}</td>
                      <td className="px-5 py-3.5">
                        <span
                          className={`rounded-full px-3 py-1 text-[13px] font-bold ${done ? "bg-success-tint text-success-foreground" : overdue ? "bg-danger-tint text-danger-foreground" : "bg-blue-50 text-primary"}`}
                        >
                          {done ? "Cumplido" : overdue ? "Vencido" : "Pendiente"}
                        </span>
                      </td>
                      {canUpdate && (
                        <td className="px-5 py-3 text-right">
                          <CompleteCommitmentButton commitmentId={c.compromiso_id} ventureId={ventureId} done={done} />
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section aria-labelledby="recommendations-title">
        <h2 id="recommendations-title" className={heading}>Recomendaciones</h2>
        {recommendations.length === 0 ? (
          <p className="rounded-2xl border border-border bg-card p-6 text-center text-muted-foreground">Todavía no hay recomendaciones.</p>
        ) : (
          <ul className="flex flex-col gap-3">
            {recommendations.map((r) => (
              <li key={r.recomendacion_id} className="rounded-2xl border border-border bg-card px-5 py-4">
                <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
                  <div className="text-[15px] font-semibold">{r.titulo}</div>
                  <div className="text-[13px] text-muted-foreground">{r.fecha ? formatDateTime(r.fecha) : "Sin fecha"}</div>
                </div>
                {r.contenido && <p className="mt-1 text-sm leading-normal text-muted-foreground">{r.contenido}</p>}
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  );
}
