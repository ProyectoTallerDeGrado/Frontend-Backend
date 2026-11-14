import "server-only";

import type { ReactNode } from "react";

import { hasPermission, requireSession } from "@/features/auth";

import { AssignAdvisorSheet } from "../components/assign-advisor-sheet";
import { listAdvisors, listAssignments } from "./queries";

export type AdvisorsColumn = { header: string; cell: (venture: { id: number; name: string }) => ReactNode };

/**
 * CU09 · Columna «Asesor» de la lista de emprendimientos: quién acompaña a cada uno y, para
 * coordinación, la acción de asignar. Devuelve `null` si el usuario no puede consultar asesorías.
 * La arma `mentoring` y la compone la página, para que `ventures` no dependa de `mentoring`.
 */
export async function buildAdvisorsColumn(): Promise<AdvisorsColumn | null> {
  const user = await requireSession();
  if (!hasPermission(user, "asesorias:consulta")) return null;
  const [advisors, assignments] = await Promise.all([listAdvisors(), listAssignments()]);
  const canAssign = hasPermission(user, "asesorias:registro") && user.rol !== "asesor";
  const enabled = advisors.filter((a) => a.habilitado);
  const active = assignments.filter((a) => a.estado === "activa");

  return {
    header: "Asesor",
    cell: (venture) => {
      const mine = active.filter((a) => a.emprendimiento_id === venture.id);
      return (
        <div className="flex flex-col items-start gap-1.5">
          {mine.length === 0 ? (
            <span className="text-[13px] text-muted-foreground">Sin asesor</span>
          ) : (
            <ul className="flex flex-col gap-0.5">
              {mine.map((a) => (
                <li key={a.asignacion_id} className="text-[13px] font-semibold leading-snug">
                  {a.usuario ?? `Asesor ${a.usuario_id}`}
                </li>
              ))}
            </ul>
          )}
          {canAssign && <AssignAdvisorSheet ventureId={venture.id} ventureName={venture.name} advisors={enabled} />}
        </div>
      );
    },
  };
}
