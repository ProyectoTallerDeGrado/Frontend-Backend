import Link from "next/link";
import { CalendarClock, ChevronRight, Bell, Rocket } from "lucide-react";

import { CountUp } from "@/components/data/count-up";
import { PageHeader } from "@/components/layout/page-header";
import { HealthAttentionCard, HealthPill, OrbitArt, ScoreBar } from "@/features/indicators";
import type { HealthReport } from "@/features/indicators";
import { formatDateTime } from "@/lib/format";

import { summarizeAdvisorSnapshot, type AdvisorSnapshot } from "../advisor-dashboard";
import type { Session } from "../types";

const card = "rounded-2xl border border-border bg-card p-6";

type Props = {
  firstName: string;
  snapshot: AdvisorSnapshot;
  /** Salud de sus emprendimientos (el backend ya la limita a los asignados). */
  health: HealthReport;
  /** Alertas abiertas de sus emprendimientos. */
  openAlerts: number;
  canManageAvailability: boolean;
};

function sessionTitle(session: Session): string {
  return session.emprendimiento ?? `Emprendimiento ${session.emprendimiento_id}`;
}

/**
 * Resumen del asesor. Mismo lenguaje visual que el Resumen de coordinación y administración
 * (`OverviewView`): banda de marca con órbitas, tarjetas de cifras y listas. Solo muestra
 * lo que el asesor puede consultar: sus emprendimientos asignados y sus mentorías.
 */
export function AdvisorDashboardView({ firstName, snapshot, health, openAlerts, canManageAvailability }: Props) {
  const summary = summarizeAdvisorSnapshot(snapshot);
  const total = summary.activeAssignments.length;
  const nextSession = summary.upcoming[0];
  const bars = [
    { label: "Por realizar", value: summary.upcoming.length, bar: "var(--primary)" },
    { label: "Realizadas", value: summary.completed.length, bar: "var(--success)" },
    { label: "Canceladas", value: summary.cancelled, bar: "var(--danger-foreground)" },
  ];
  const maxBar = Math.max(1, ...bars.map((b) => b.value));

  return (
    <>
      <PageHeader title={`Hola, ${firstName}`} subtitle="Así va tu acompañamiento: mentorías y emprendimientos asignados." />

      <div className="flex flex-col gap-6">
        <section
          aria-label="Acompañamiento"
          className="relative isolate overflow-hidden rounded-3xl bg-navy-950 px-6 py-7 text-white sm:px-9 sm:py-9"
        >
          <OrbitArt satellites={total} />
          <div className="relative max-w-[560px]">
            <p className="text-[15px] font-semibold text-on-navy-faint">Emprendimientos que acompañas</p>
            <p className="mt-1 font-heading text-[64px] leading-none font-bold tracking-[-.03em] sm:text-[84px]">
              <CountUp value={total} duration={1400} />
            </p>
            <p className="mt-2 font-heading text-xl font-semibold text-on-navy-muted">
              {total === 1 ? "asignación activa" : "asignaciones activas"}
            </p>
            {nextSession ? (
              <p className="mt-4 flex items-center gap-2 text-[15px] text-on-navy-muted">
                <CalendarClock aria-hidden="true" className="size-[18px] text-accent-bright" />
                Próxima: {sessionTitle(nextSession)} · {formatDateTime(nextSession.fecha_programada)}
              </p>
            ) : (
              <p className="mt-4 text-[15px] text-on-navy-muted">No tienes mentorías programadas.</p>
            )}
            <div className="mt-7 flex flex-wrap gap-3">
              <Link
                href="/alerts"
                className="group/alerts inline-flex min-h-12 items-center gap-2.5 rounded-xl bg-white/10 px-4 text-[15px] font-semibold outline-none backdrop-blur-sm transition-colors hover:bg-white/[.16] focus-visible:ring-3 focus-visible:ring-white/50"
              >
                <Bell aria-hidden="true" className={`size-[18px] ${openAlerts > 0 ? "text-accent-bright" : ""}`} />
                {openAlerts === 0 ? "Sin alertas abiertas" : openAlerts === 1 ? "1 alerta abierta" : `${openAlerts} alertas abiertas`}
                <ChevronRight aria-hidden="true" className="size-4 transition-transform group-hover/alerts:translate-x-0.5" />
              </Link>
              <Link
                href="/mentoring/sessions"
                className="inline-flex min-h-12 items-center rounded-xl px-4 text-[15px] font-semibold text-on-navy-muted outline-none transition-colors hover:bg-white/10 hover:text-white focus-visible:ring-3 focus-visible:ring-white/50"
              >
                Ver mis sesiones
              </Link>
            </div>
          </div>
        </section>

        <div className="flex flex-wrap gap-6">
          <section aria-labelledby="mentoring-title" className={`${card} min-w-0 flex-[1.4_1_420px]`}>
            <div className="mb-5 flex flex-wrap items-start justify-between gap-3">
              <div>
                <h2 id="mentoring-title" className="font-heading text-lg font-semibold">
                  Mis mentorías
                </h2>
                <p className="text-sm text-muted-foreground">Tus sesiones por estado.</p>
              </div>
              {canManageAvailability && (
                <Link href="/mentoring/availability" className="inline-flex min-h-11 items-center text-sm font-semibold text-primary hover:underline">
                  Mi disponibilidad
                </Link>
              )}
            </div>
            <dl className="mb-6 grid grid-cols-3 gap-3">
              {[
                { label: "Este mes", value: summary.completedThisMonth, tone: "text-foreground" },
                { label: "Por registrar", value: summary.pendingResults.length, tone: "text-warning-foreground" },
                { label: "Compromisos", value: summary.commitments, tone: "text-foreground" },
              ].map((k, i) => (
                <div key={k.label} className="rounded-xl bg-background px-4 py-3">
                  <dt className="text-[13px] font-semibold text-muted-foreground">{k.label}</dt>
                  <dd className={`font-heading text-[28px] leading-tight font-bold tracking-[-.02em] ${k.tone}`}>
                    <CountUp value={k.value} delay={150 + i * 90} />
                  </dd>
                </div>
              ))}
            </dl>
            <div className="flex flex-col gap-4">
              {bars.map((b, i) => (
                <div key={b.label}>
                  <div className="mb-1.5 flex justify-between text-sm font-semibold">
                    <span>{b.label}</span>
                    <span className="tabular-nums">{b.value}</span>
                  </div>
                  <div className="h-2.5 overflow-hidden rounded-full bg-muted">
                    <div
                      className="h-full origin-left animate-[grow-x_.9s_cubic-bezier(.2,.7,.2,1)_both] rounded-full"
                      style={{ width: `${(b.value / maxBar) * 100}%`, background: b.bar, animationDelay: `${350 + i * 110}ms` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section aria-labelledby="upcoming-title" className={`${card} min-w-0 flex-[1_1_320px]`}>
            <div className="flex items-center justify-between gap-3">
              <h2 id="upcoming-title" className="font-heading text-lg font-semibold">
                Próximas mentorías
              </h2>
              <Link href="/mentoring/sessions?estado=programada" className="text-sm font-semibold text-primary hover:underline">
                Ver todas
              </Link>
            </div>
            {summary.upcoming.length === 0 ? (
              <div className="mt-4 rounded-xl border border-dashed border-border-strong px-5 py-8 text-center">
                <CalendarClock aria-hidden="true" className="mx-auto size-7 text-primary" />
                <p className="mt-3 font-semibold">Tu agenda está libre</p>
                <p className="mt-1 text-sm text-muted-foreground">No tienes sesiones programadas.</p>
              </div>
            ) : (
              <ul className="mt-3">
                {summary.upcoming.slice(0, 5).map((session) => (
                  <li key={session.sesion_id} className="flex items-start gap-3 border-t border-muted py-3 first:border-t-0">
                    <span className="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-xl bg-blue-50 text-primary">
                      <Rocket aria-hidden="true" className="size-4" />
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-[15px] font-semibold">{sessionTitle(session)}</p>
                      <p className="truncate text-[13px] text-muted-foreground">
                        {session.tema ?? "Tema por definir"}
                        {session.modalidad ? ` · ${session.modalidad}` : ""}
                      </p>
                      <p className="mt-0.5 text-[13px] font-medium text-muted-foreground">{formatDateTime(session.fecha_programada)}</p>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>

        <div className="flex flex-wrap gap-6">
          <div className="min-w-0 flex-[1_1_420px]">
            <HealthAttentionCard report={health} />
          </div>

          <section aria-labelledby="assigned-title" className={`${card} min-w-0 flex-[1_1_420px]`}>
            <h2 id="assigned-title" className="font-heading text-lg font-semibold">
              Mis emprendimientos
            </h2>
            <p className="mb-3 text-sm text-muted-foreground">Semáforo de salud de cada uno.</p>
            {health.emprendimientos.length === 0 ? (
              <p className="text-sm text-muted-foreground">Aún no tienes emprendimientos asignados. Coordinación administra las asignaciones.</p>
            ) : (
              <ul>
                {health.emprendimientos.map((venture) => (
                  <li key={venture.emprendimiento_id} className="flex flex-wrap items-center justify-between gap-3 border-t border-muted py-3.5 first:border-t-0">
                    <div className="min-w-0">
                      <Link href={`/ventures/${venture.emprendimiento_id}/follow-up`} className="font-semibold hover:underline">
                        {venture.nombre}
                      </Link>
                      <div className="text-[13px] text-muted-foreground">
                        {venture.etapa ?? "Sin etapa"}
                        {venture.alertas_abiertas > 0 ? ` · ${venture.alertas_abiertas} alerta(s) abierta(s)` : ""}
                        {venture.compromisos_vencidos > 0 ? ` · ${venture.compromisos_vencidos} compromiso(s) vencido(s)` : ""}
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <ScoreBar score={venture.puntaje} level={venture.nivel} />
                      <HealthPill level={venture.nivel} />
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>
      </div>
    </>
  );
}
