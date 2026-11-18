import Link from "next/link";
import type { ReactNode } from "react";
import {
  ArrowRight,
  CalendarCheck,
  CalendarClock,
  CheckCircle2,
  ClipboardCheck,
  Lightbulb,
  Rocket,
} from "lucide-react";

import { CountUp } from "@/components/data/count-up";
import { PageHeader } from "@/components/layout/page-header";
import { boDay, formatDateTime } from "@/lib/format";

import { getAdvisorDashboardSnapshot } from "../server/queries";
import type { Session } from "../types";

const stateBadge: Record<string, string> = {
  programada: "bg-blue-50 text-primary",
  realizada: "bg-success-tint text-success-foreground",
  cancelada: "bg-danger-tint text-danger-foreground",
};

function sessionTime(session: Session): number {
  const value = session.fecha_programada ?? session.fecha_realizada;
  return value ? new Date(value).getTime() : 0;
}

function Metric({
  icon: Icon,
  label,
  value,
  hint,
}: {
  icon: typeof CalendarClock;
  label: string;
  value: number;
  hint: string;
}) {
  return (
    <article className="rounded-2xl border border-border bg-card p-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-[13px] font-semibold text-muted-foreground">{label}</p>
          <p className="mt-2 font-heading text-[34px] leading-none font-bold tracking-[-.02em] text-primary tabular-nums">
            <CountUp value={value} />
          </p>
        </div>
        <span className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-blue-50 text-primary">
          <Icon aria-hidden="true" className="size-5" />
        </span>
      </div>
      <p className="mt-3 text-[13px] leading-normal text-muted-foreground">{hint}</p>
    </article>
  );
}

function TextLink({ href, children }: { href: string; children: ReactNode }) {
  return (
    <Link
      href={href}
      className="inline-flex min-h-11 items-center gap-2 rounded-xl px-3 text-sm font-semibold text-primary outline-none transition-colors hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
    >
      {children}
      <ArrowRight aria-hidden="true" className="size-4" />
    </Link>
  );
}

/** Panel operativo del asesor: agenda, carga asignada y resultados de sus mentorías. */
export async function AdvisorDashboardScreen({
  firstName,
  canManageAvailability,
  canRegisterSessions,
}: {
  firstName: string;
  canManageAvailability: boolean;
  canRegisterSessions: boolean;
}) {
  const { sessions, assignments, generatedAt, currentMonth } = await getAdvisorDashboardSnapshot();
  const activeAssignments = assignments.filter((assignment) => assignment.estado === "activa");
  const completed = sessions.filter((session) => session.estado === "realizada");
  const completedThisMonth = completed.filter((session) => {
    const date = session.fecha_realizada ?? session.fecha_programada;
    return date ? boDay(date).startsWith(currentMonth) : false;
  });
  const upcoming = sessions
    .filter((session) => session.estado === "programada" && sessionTime(session) >= generatedAt)
    .sort((a, b) => sessionTime(a) - sessionTime(b));
  const nextSession = upcoming[0];
  const recent = [...sessions]
    .filter((session) => sessionTime(session) > 0)
    .sort((a, b) => sessionTime(b) - sessionTime(a))
    .slice(0, 4);
  const recommendations = sessions.reduce((total, session) => total + session.total_recomendaciones, 0);
  const commitments = sessions.reduce((total, session) => total + session.total_compromisos, 0);

  return (
    <>
      <PageHeader
        title={`Hola, ${firstName}`}
        subtitle="Organiza tus próximas mentorías y revisa el acompañamiento que has registrado."
        actions={canManageAvailability ? <TextLink href="/mentoring/availability">Actualizar mi disponibilidad</TextLink> : undefined}
      />

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.35fr)_minmax(360px,.65fr)]">
        <section className="relative overflow-hidden rounded-2xl bg-navy-900 p-6 text-white sm:p-7">
          <div aria-hidden="true" className="absolute -right-16 -top-24 size-64 rounded-full border border-white/15" />
          <div aria-hidden="true" className="absolute -right-4 -top-12 size-40 rounded-full border border-accent-bright/40" />
          <div className="relative flex min-h-60 flex-col">
            <div className="flex items-center gap-2 text-sm font-semibold text-on-navy-muted">
              <CalendarClock aria-hidden="true" className="size-5 text-accent-bright" />
              Próxima mentoría
            </div>
            {nextSession ? (
              <>
                <p className="mt-8 font-heading text-2xl leading-tight font-semibold text-balance sm:text-[30px]">
                  {nextSession.emprendimiento ?? `Emprendimiento ${nextSession.emprendimiento_id}`}
                </p>
                <p className="mt-2 text-base text-on-navy-muted">
                  {nextSession.tema ?? "Tema por definir"}
                  {nextSession.modalidad ? ` · ${nextSession.modalidad}` : ""}
                </p>
                <p className="mt-5 font-heading text-lg font-semibold">{formatDateTime(nextSession.fecha_programada)}</p>
                <Link
                  href="/mentoring/sessions?estado=programada"
                  className="mt-auto inline-flex min-h-11 w-fit items-center gap-2 rounded-xl bg-white px-4 text-sm font-semibold text-navy-900 outline-none transition-colors hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-white/60"
                >
                  Ver agenda
                  <ArrowRight aria-hidden="true" className="size-4" />
                </Link>
              </>
            ) : (
              <>
                <p className="mt-8 font-heading text-2xl font-semibold text-balance">Tu agenda está libre</p>
                <p className="mt-2 max-w-md text-[15px] leading-relaxed text-on-navy-muted">
                  No tienes mentorías programadas. Revisa que tus horarios disponibles estén actualizados.
                </p>
                <Link
                  href={canManageAvailability ? "/mentoring/availability" : "/mentoring/sessions"}
                  className="mt-auto inline-flex min-h-11 w-fit items-center gap-2 rounded-xl bg-white px-4 text-sm font-semibold text-navy-900 outline-none transition-colors hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-white/60"
                >
                  {canManageAvailability ? "Revisar disponibilidad" : "Ver mis sesiones"}
                  <ArrowRight aria-hidden="true" className="size-4" />
                </Link>
              </>
            )}
          </div>
        </section>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Metric icon={CalendarCheck} label="Por realizar" value={upcoming.length} hint="mentorías en tu agenda" />
          <Metric icon={CheckCircle2} label="Realizadas este mes" value={completedThisMonth.length} hint={`${completed.length} realizadas en total`} />
          <Metric icon={Rocket} label="Emprendimientos" value={activeAssignments.length} hint="asignaciones activas" />
          <Metric icon={ClipboardCheck} label="Seguimientos" value={commitments} hint={`${recommendations} recomendaciones registradas`} />
        </div>
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-2">
        <section className="rounded-2xl border border-border bg-card p-5 sm:p-6" aria-labelledby="assigned-ventures-title">
          <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
            <div>
              <h2 id="assigned-ventures-title" className="font-heading text-lg font-semibold">Emprendimientos que acompañas</h2>
              <p className="mt-1 text-sm text-muted-foreground">Tus asignaciones activas.</p>
            </div>
            <TextLink href="/mentoring/sessions">{canRegisterSessions ? "Registrar mentoría" : "Ver sesiones"}</TextLink>
          </div>
          {activeAssignments.length > 0 ? (
            <ul className="divide-y divide-muted">
              {activeAssignments.slice(0, 5).map((assignment) => (
                <li key={assignment.asignacion_id} className="flex items-center gap-3 py-3.5 first:pt-1 last:pb-1">
                  <span className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-danger-tint text-danger-foreground">
                    <Rocket aria-hidden="true" className="size-5" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[15px] font-semibold">{assignment.emprendimiento ?? `Emprendimiento ${assignment.emprendimiento_id}`}</p>
                    <p className="mt-0.5 text-[13px] text-muted-foreground">{assignment.tipo_asignacion ?? "Asesoría"}</p>
                  </div>
                  <Link
                    href={`/ventures/${assignment.emprendimiento_id}/follow-up`}
                    aria-label={`Ver seguimiento de ${assignment.emprendimiento ?? "emprendimiento"}`}
                    className="inline-flex min-h-11 items-center rounded-xl px-3 text-sm font-semibold text-primary outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
                  >
                    Ver seguimiento
                  </Link>
                </li>
              ))}
            </ul>
          ) : (
            <div className="rounded-xl border border-dashed border-border-strong px-5 py-8 text-center">
              <Rocket aria-hidden="true" className="mx-auto size-7 text-primary" />
              <p className="mt-3 font-semibold">Aún no tienes emprendimientos asignados</p>
              <p className="mt-1 text-sm text-muted-foreground">Coordinación administra las asignaciones del programa.</p>
            </div>
          )}
        </section>

        <section className="rounded-2xl border border-border bg-card p-5 sm:p-6" aria-labelledby="recent-sessions-title">
          <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
            <div>
              <h2 id="recent-sessions-title" className="font-heading text-lg font-semibold">Actividad de mentorías</h2>
              <p className="mt-1 text-sm text-muted-foreground">Tus sesiones más recientes.</p>
            </div>
            <TextLink href="/mentoring/sessions">Ver todas</TextLink>
          </div>
          {recent.length > 0 ? (
            <ul className="divide-y divide-muted">
              {recent.map((session) => (
                <li key={session.sesion_id} className="flex items-start gap-3 py-3.5 first:pt-1 last:pb-1">
                  <span className="mt-0.5 flex size-10 shrink-0 items-center justify-center rounded-xl bg-blue-50 text-primary">
                    <Lightbulb aria-hidden="true" className="size-5" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="min-w-0 flex-1 truncate text-[15px] font-semibold">{session.emprendimiento ?? `Emprendimiento ${session.emprendimiento_id}`}</p>
                      <span className={`rounded-full px-2.5 py-1 text-xs font-bold ${stateBadge[session.estado ?? ""] ?? "bg-muted text-muted-foreground"}`}>
                        {session.estado ?? "Sin estado"}
                      </span>
                    </div>
                    <p className="mt-1 truncate text-sm text-muted-foreground">{session.tema ?? "Tema por definir"}</p>
                    <p className="mt-1 text-[13px] font-medium text-muted-foreground">{formatDateTime(session.fecha_realizada ?? session.fecha_programada)}</p>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="rounded-xl border border-dashed border-border-strong px-5 py-8 text-center">
              <CalendarCheck aria-hidden="true" className="mx-auto size-7 text-primary" />
              <p className="mt-3 font-semibold">Todavía no registraste mentorías</p>
              <p className="mt-1 text-sm text-muted-foreground">Cuando registres una sesión, aparecerá aquí.</p>
            </div>
          )}
        </section>
      </div>
    </>
  );
}
