import { ROLE_META } from "@/features/users";

import type { Overview } from "../types";

const card =
  "rounded-2xl border border-border bg-card p-6 transition-shadow hover:shadow-[0_14px_30px_-18px_rgba(10,26,68,.35)]";

export function OverviewView({ overview }: { overview: Overview }) {
  const { usuarios } = overview;
  const kpis = [
    { label: "Usuarios registrados", value: usuarios.total, note: "Todos los roles", color: "text-foreground" },
    { label: "Cuentas habilitadas", value: usuarios.habilitadas, note: "Con acceso a la plataforma", color: "text-success-foreground" },
    { label: "Cuentas deshabilitadas", value: usuarios.deshabilitadas, note: "Sin acceso", color: "text-[#8f0f25]" },
    { label: "Emprendimientos activos", value: overview.emprendimientos_activos, note: `${overview.alertas_abiertas} alertas abiertas`, color: "text-primary" },
  ];
  const max = Math.max(1, ...Object.values(usuarios.por_rol));

  return (
    <div className="flex flex-col gap-6">
      <div className="grid grid-cols-[repeat(auto-fit,minmax(min(220px,100%),1fr))] gap-4">
        {kpis.map((k, i) => (
          <div
            key={k.label}
            className={`${card} animate-[fade-up_.55s_ease_both] px-[22px] py-5`}
            style={{ animationDelay: `${i * 70}ms` }}
          >
            <div className="text-sm font-semibold text-muted-foreground">{k.label}</div>
            <div className={`mt-2.5 font-heading text-[38px] font-bold tracking-[-.02em] ${k.color}`}>{k.value}</div>
            <div className="mt-0.5 text-[13px] text-muted-foreground">{k.note}</div>
          </div>
        ))}
      </div>

      <div className="flex flex-wrap gap-6">
        <section className={`${card} min-w-0 flex-[1.4_1_420px]`}>
          <h2 className="mb-1 font-heading text-lg font-semibold">Usuarios por rol</h2>
          <p className="mb-[22px] text-sm text-muted-foreground">Distribución de cuentas registradas en la plataforma.</p>
          <div className="flex flex-col gap-[18px]">
            {Object.entries(ROLE_META).map(([key, meta], i) => {
              const count = usuarios.por_rol[key] ?? 0;
              return (
                <div key={key}>
                  <div className="mb-2 flex justify-between text-sm font-semibold">
                    <span>{meta.label}</span>
                    <span>{count}</span>
                  </div>
                  <div className="h-3 overflow-hidden rounded-full bg-[#eef2fa]">
                    <div
                      className="h-full origin-left animate-[grow-x_.9s_cubic-bezier(.2,.7,.2,1)_both] rounded-full"
                      style={{ width: `${(count / max) * 100}%`, background: meta.bar, animationDelay: `${200 + i * 120}ms` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </section>

        <section className={`${card} min-w-0 flex-[1_1_320px]`}>
          <h2 className="mb-1 font-heading text-lg font-semibold">Estado de la plataforma</h2>
          <p className="mb-[18px] text-sm text-muted-foreground">Supervisión de servicios.</p>
          <ul>
            {overview.servicios.map((s) => {
              const ok = s.estado === "operativo";
              return (
                <li key={s.nombre} className="flex items-center gap-3.5 border-t border-[#eef2fa] py-3.5">
                  <span
                    aria-hidden="true"
                    className={`size-2.5 shrink-0 rounded-full ${ok ? "animate-[pulse-dot_2.2s_ease-out_infinite] bg-[#0e7a4f]" : "bg-[#b26a00]"}`}
                  />
                  <div className="min-w-0 flex-1">
                    <div className="text-[15px] font-semibold">{s.nombre}</div>
                    <div className="text-[13px] text-muted-foreground">{s.detalle}</div>
                  </div>
                  <span
                    className={`rounded-full px-2.5 py-1 text-[13px] font-bold ${ok ? "bg-success-tint text-success-foreground" : "bg-[#fff0cc] text-[#5e3f00]"}`}
                  >
                    {ok ? "Operativo" : "Degradado"}
                  </span>
                </li>
              );
            })}
          </ul>
        </section>
      </div>
    </div>
  );
}
