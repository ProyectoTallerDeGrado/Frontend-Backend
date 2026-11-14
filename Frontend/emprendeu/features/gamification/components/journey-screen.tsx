import Link from "next/link";
import { Award, CheckCircle2, Circle, Lock, PlayCircle, type LucideIcon } from "lucide-react";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { getJourney } from "../server/queries";

const STAGE: Record<string, { label: string; tone: string }> = {
  cumplida: { label: "Completada", tone: "bg-success-tint text-success-foreground" },
  en_curso: { label: "Actual", tone: "bg-blue-50 text-primary" },
  bloqueada: { label: "Pendiente", tone: "bg-muted text-muted-foreground" },
};

const CHALLENGE: Record<string, { label: string; icon: LucideIcon; tone: string }> = {
  cumplido: { label: "Cumplido", icon: CheckCircle2, tone: "text-success-foreground" },
  en_curso: { label: "En curso", icon: PlayCircle, tone: "text-primary" },
  bloqueado: { label: "Bloqueado", icon: Lock, tone: "text-muted-foreground" },
};

/** CU06 · Progreso gamificado del emprendimiento: etapas completadas, actual y pendientes, con sus retos. */
export async function JourneyScreen({ ventureId, ventureName }: { ventureId: number; ventureName: string }) {
  const user = await requireSession();
  if (!hasPermission(user, "seguimiento:consulta")) return <NoAccess section="Progreso" />;
  const journey = await getJourney(ventureId);
  const done = journey.retos.filter((r) => r.estado === "cumplido").length;

  return (
    <>
      <PageHeader
        title={`Progreso · ${ventureName}`}
        subtitle="Etapas del camino y retos del emprendimiento. Solo el emprendedor cumple sus retos desde la app."
      />
      <Link href="/ventures" className="mb-5 inline-flex min-h-11 items-center text-sm font-semibold text-primary">
        ← Volver a emprendimientos
      </Link>

      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        {[
          ["XP acumulado", String(journey.xp_total)],
          ["Nivel", String(journey.nivel)],
          ["Retos cumplidos", `${done} de ${journey.retos.length}`],
        ].map(([label, value]) => (
          <div key={label} className="rounded-2xl border border-border bg-card px-5 py-4">
            <div className="text-[13px] font-semibold text-muted-foreground">{label}</div>
            <div className="mt-1 font-heading text-2xl font-semibold">{value}</div>
          </div>
        ))}
      </div>

      <div className="mb-8 rounded-2xl border border-border bg-card px-5 py-4">
        <div className="mb-2 flex flex-wrap justify-between gap-2 text-[13px] font-semibold text-muted-foreground">
          <span>Progreso hacia el nivel {journey.nivel + 1}</span>
          <span>
            {journey.xp_faltante === null
              ? "Nivel máximo alcanzado"
              : `${journey.xp_total} / ${journey.xp_siguiente_nivel} XP · faltan ${journey.xp_faltante}`}
          </span>
        </div>
        <div
          role="progressbar"
          aria-valuenow={journey.progreso_pct}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-label="Progreso hacia el siguiente nivel"
          className="h-3 overflow-hidden rounded-full bg-muted"
        >
          <div className="h-full rounded-full bg-primary" style={{ width: `${journey.progreso_pct}%` }} />
        </div>
      </div>

      <h2 className="mb-3 font-heading text-lg font-semibold">Etapas</h2>
      {journey.etapas.length === 0 ? (
        <p className="mb-8 rounded-2xl border border-border bg-card p-8 text-center text-muted-foreground">
          No hay etapas configuradas con retos activos.
        </p>
      ) : (
        <ol className="mb-8 flex flex-wrap gap-3">
          {journey.etapas.map((e) => (
            <li key={e.etapa_id} className={`rounded-full px-4 py-2 text-sm font-bold ${STAGE[e.estado].tone}`}>
              {e.nombre} · {STAGE[e.estado].label}
            </li>
          ))}
        </ol>
      )}

      <h2 className="mb-3 font-heading text-lg font-semibold">Insignias</h2>
      <ul className="mb-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {journey.insignias.map((b) => (
          <li
            key={b.insignia_id}
            className={`flex items-start gap-3 rounded-2xl border border-border bg-card px-5 py-4 ${b.obtenida ? "" : "opacity-60"}`}
          >
            <Award
              aria-hidden="true"
              className={`mt-0.5 size-6 shrink-0 ${b.obtenida ? "text-primary" : "text-muted-foreground"}`}
            />
            <div className="min-w-0">
              <div className="text-[15px] font-semibold">{b.nombre}</div>
              {b.criterio && <p className="text-[13px] text-muted-foreground">{b.criterio}</p>}
              <div className="mt-1 text-[13px] font-semibold">
                {b.obtenida
                  ? `Obtenida${b.fecha_obtenida ? ` · ${formatDateTime(b.fecha_obtenida)}` : ""}`
                  : "Pendiente"}
              </div>
            </div>
          </li>
        ))}
      </ul>

      <h2 className="mb-3 font-heading text-lg font-semibold">Historial de XP</h2>
      {journey.historial.length === 0 ? (
        <p className="mb-8 rounded-2xl border border-border bg-card p-8 text-center text-muted-foreground">
          Todavía no hay progreso registrado: el emprendimiento aún no ha ganado XP.
        </p>
      ) : (
        <ul className="mb-8 divide-y divide-border rounded-2xl border border-border bg-card">
          {journey.historial.map((m, i) => (
            <li key={i} className="flex flex-wrap items-baseline justify-between gap-x-4 px-5 py-3 text-sm">
              <span className="font-semibold">{m.motivo ?? "Movimiento de XP"}</span>
              <span className="text-muted-foreground">
                {m.fecha ? formatDateTime(m.fecha) : ""} · <b className="text-primary">+{m.cantidad} XP</b>
              </span>
            </li>
          ))}
        </ul>
      )}

      <h2 className="mb-3 font-heading text-lg font-semibold">Retos</h2>
      {journey.retos.length === 0 ? (
        <p className="rounded-2xl border border-border bg-card p-8 text-center text-muted-foreground">
          Todavía no hay retos activos.
        </p>
      ) : (
        <ul className="flex flex-col gap-3">
          {journey.retos.map((r) => {
            const c = CHALLENGE[r.estado];
            const Icon = r.estado === "bloqueado" ? Circle : c.icon;
            return (
              <li key={r.reto_id} className="flex items-start gap-4 rounded-2xl border border-border bg-card px-5 py-4">
                <Icon aria-hidden="true" className={`mt-0.5 size-6 shrink-0 ${c.tone}`} />
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-baseline justify-between gap-x-4">
                    <div className="text-[15px] font-semibold">{r.titulo}</div>
                    <div className="text-[13px] font-bold text-primary">+{r.xp_recompensa} XP</div>
                  </div>
                  {r.descripcion && <p className="mt-1 text-sm leading-normal text-muted-foreground">{r.descripcion}</p>}
                  <div className="mt-2 flex flex-wrap gap-x-3 text-[13px] text-muted-foreground">
                    <span className={`font-semibold ${c.tone}`}>{c.label}</span>
                    {r.etapa && <span>Etapa: {r.etapa}</span>}
                    {r.fecha_completado && <span>Cumplido {formatDateTime(r.fecha_completado)}</span>}
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </>
  );
}
