import Link from "next/link";
import { Bell, ChevronRight } from "lucide-react";

import { CountUp } from "@/components/data/count-up";
import { StatusPill } from "@/components/data/status-pill";
import { ROLE_META } from "@/features/users";

import type { Overview } from "../types";
import { OrbitArt } from "./orbit-art";

const card = "rounded-2xl border border-border bg-card p-6";

type Props = {
  overview: Overview;
  /** Enlaces que el usuario puede abrir (según sus permisos). */
  links?: { alerts?: boolean; ventures?: boolean; users?: boolean };
};

/**
 * Resumen de la plataforma. La franja de marca muestra el tamaño del programa
 * (emprendimientos activos, uno por satélite) y lo urgente (alertas abiertas).
 */
export function OverviewView({ overview, links = {} }: Props) {
  const { usuarios } = overview;
  const max = Math.max(1, ...Object.values(usuarios.por_rol));
  const alerts = overview.alertas_abiertas;

  return (
    <div className="flex flex-col gap-6">
      <section
        aria-label="Programa"
        className="relative isolate overflow-hidden rounded-3xl bg-navy-950 px-6 py-7 text-white sm:px-9 sm:py-9"
      >
        <OrbitArt satellites={overview.emprendimientos_activos} />
        <div className="relative max-w-[560px]">
          <p className="text-[15px] font-semibold text-on-navy-faint">En el programa ahora</p>
          <p className="mt-1 font-heading text-[64px] leading-none font-bold tracking-[-.03em] sm:text-[84px]">
            <CountUp value={overview.emprendimientos_activos} duration={1400} />
          </p>
          <p className="mt-2 font-heading text-xl font-semibold text-on-navy-muted">
            {overview.emprendimientos_activos === 1 ? "emprendimiento activo" : "emprendimientos activos"}
          </p>
          <div className="mt-7 flex flex-wrap gap-3">
            {links.alerts ? (
              <Link
                href="/alerts"
                className="group/alerts inline-flex min-h-12 items-center gap-2.5 rounded-xl bg-white/10 px-4 text-[15px] font-semibold outline-none backdrop-blur-sm transition-colors hover:bg-white/[.16] focus-visible:ring-3 focus-visible:ring-white/50"
              >
                <Bell aria-hidden="true" className={`size-[18px] ${alerts > 0 ? "text-accent-bright" : ""}`} />
                {alerts === 0 ? "Sin alertas abiertas" : alerts === 1 ? "1 alerta abierta" : `${alerts} alertas abiertas`}
                <ChevronRight aria-hidden="true" className="size-4 transition-transform group-hover/alerts:translate-x-0.5" />
              </Link>
            ) : (
              <span className="inline-flex min-h-12 items-center gap-2.5 rounded-xl bg-white/10 px-4 text-[15px] font-semibold">
                <Bell aria-hidden="true" className="size-[18px]" />
                {alerts === 1 ? "1 alerta abierta" : `${alerts} alertas abiertas`}
              </span>
            )}
            {links.ventures && (
              <Link
                href="/ventures"
                className="inline-flex min-h-12 items-center rounded-xl px-4 text-[15px] font-semibold text-on-navy-muted outline-none transition-colors hover:bg-white/10 hover:text-white focus-visible:ring-3 focus-visible:ring-white/50"
              >
                Ver emprendimientos
              </Link>
            )}
          </div>
        </div>
      </section>

      <div className="flex flex-wrap gap-6">
        <section aria-labelledby="accounts-title" className={`${card} min-w-0 flex-[1.4_1_420px]`}>
          <div className="mb-5 flex flex-wrap items-start justify-between gap-3">
            <div>
              <h2 id="accounts-title" className="font-heading text-lg font-semibold">
                Cuentas
              </h2>
              <p className="text-sm text-muted-foreground">Quién usa la plataforma, por rol.</p>
            </div>
            {links.users && (
              <Link href="/users" className="inline-flex min-h-11 items-center text-sm font-semibold text-primary hover:underline">
                Gestionar usuarios
              </Link>
            )}
          </div>
          <dl className="mb-6 grid grid-cols-3 gap-3">
            {[
              { label: "Registradas", value: usuarios.total, tone: "text-foreground" },
              { label: "Habilitadas", value: usuarios.habilitadas, tone: "text-success-foreground" },
              { label: "Deshabilitadas", value: usuarios.deshabilitadas, tone: "text-danger-foreground" },
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
            {Object.entries(ROLE_META).map(([key, meta], i) => {
              const count = usuarios.por_rol[key] ?? 0;
              return (
                <div key={key}>
                  <div className="mb-1.5 flex justify-between text-sm font-semibold">
                    <span>{meta.label}</span>
                    <span className="tabular-nums">{count}</span>
                  </div>
                  <div className="h-2.5 overflow-hidden rounded-full bg-muted">
                    <div
                      className="h-full origin-left animate-[grow-x_.9s_cubic-bezier(.2,.7,.2,1)_both] rounded-full"
                      style={{ width: `${(count / max) * 100}%`, background: meta.bar, animationDelay: `${350 + i * 110}ms` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </section>

        <section aria-labelledby="services-title" className={`${card} min-w-0 flex-[1_1_320px]`}>
          <h2 id="services-title" className="font-heading text-lg font-semibold">
            Estado de la plataforma
          </h2>
          <p className="mb-3 text-sm text-muted-foreground">Servicios de los que depende el panel y la app.</p>
          <ul>
            {overview.servicios.map((s) => {
              const ok = s.estado === "operativo";
              return (
                <li key={s.nombre} className="flex items-center gap-3.5 border-t border-muted py-3.5 first:border-t-0">
                  <span
                    aria-hidden="true"
                    className={`size-2.5 shrink-0 rounded-full ${ok ? "animate-[pulse-dot_2.2s_ease-out_infinite] bg-success" : "bg-gold"}`}
                  />
                  <div className="min-w-0 flex-1">
                    <div className="text-[15px] font-semibold">{s.nombre}</div>
                    <div className="text-[13px] text-muted-foreground">{s.detalle}</div>
                  </div>
                  <StatusPill tone={ok ? "success" : "warning"}>{ok ? "Operativo" : "Degradado"}</StatusPill>
                </li>
              );
            })}
          </ul>
        </section>
      </div>
    </div>
  );
}
