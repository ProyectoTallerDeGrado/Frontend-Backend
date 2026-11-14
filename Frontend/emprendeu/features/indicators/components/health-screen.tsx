import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";

import { getHealth } from "../server/queries";
import { HealthPill, LEVEL, ScoreBar } from "./health-level";

const card = "rounded-2xl border border-border bg-card px-5 py-4";

/**
 * Salud de los emprendimientos activos: un puntaje 0–100 para ordenar y, sobre todo,
 * los motivos, para saber a quién atender primero y por qué.
 */
export async function HealthScreen() {
  const user = await requireSession();
  if (user.rol === "emprendedor" || !hasPermission(user, "seguimiento:consulta"))
    return <NoAccess section="Salud de emprendimientos" />;
  const report = await getHealth();
  const rows = report.emprendimientos;
  const count = (level: keyof typeof LEVEL) => rows.filter((r) => r.nivel === level).length;

  return (
    <>
      <PageHeader
        title="Salud de los emprendimientos"
        subtitle="Del más urgente al que mejor va. Combina alertas, compromisos vencidos, inactividad, tiempo en la etapa y ánimo en el coach."
      />

      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        {(["rojo", "ambar", "verde"] as const).map((level) => (
          <div key={level} className={card}>
            <HealthPill level={level} />
            <div className="mt-2 font-heading text-[30px] leading-none font-bold">{count(level)}</div>
          </div>
        ))}
      </div>

      <div className="relative overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[820px] border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
              <th scope="col" className="px-5 py-3.5">Emprendimiento</th>
              <th scope="col" className="px-5 py-3.5">Estado</th>
              <th scope="col" className="px-5 py-3.5">Puntaje</th>
              <th scope="col" className="px-5 py-3.5">Por qué</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && (
              <tr>
                <td colSpan={4} className="px-5 py-10 text-center text-muted-foreground">
                  {user.rol === "asesor"
                    ? "No tienes emprendimientos asignados."
                    : "No hay emprendimientos activos."}
                </td>
              </tr>
            )}
            {rows.map((r) => (
              <tr key={r.emprendimiento_id} className="border-t border-muted align-top transition-colors hover:bg-row-hover">
                <td className="px-5 py-3.5">
                  <Link href={`/ventures/${r.emprendimiento_id}`} className="font-semibold text-primary hover:underline">
                    {r.nombre}
                  </Link>
                  {r.etapa && <div className="text-[13px] text-muted-foreground">{r.etapa}</div>}
                </td>
                <td className="px-5 py-3.5">
                  <HealthPill level={r.nivel} />
                </td>
                <td className="px-5 py-3.5">
                  <ScoreBar score={r.puntaje} level={r.nivel} />
                </td>
                <td className="px-5 py-3.5">
                  {r.motivos.length === 0 ? (
                    <span className="text-muted-foreground">Sin señales de riesgo</span>
                  ) : (
                    <ul className="flex flex-wrap gap-1.5">
                      {r.motivos.map((m) => (
                        <li key={m} className="rounded-full bg-muted px-2.5 py-0.5 text-[13px]">
                          {m}
                        </li>
                      ))}
                    </ul>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
