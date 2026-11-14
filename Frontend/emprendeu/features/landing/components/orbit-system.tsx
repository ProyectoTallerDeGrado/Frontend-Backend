import { createSeededRandom } from "animejs";

import { ORBIT_LABELS } from "../content";

/** Radio de cada anillo en unidades del viewBox (600 × 600, centro en 300). */
export const RINGS = [
  { r: 120, period: 26000, dashed: false },
  { r: 195, period: 42000, dashed: true },
  { r: 270, period: 64000, dashed: false },
] as const;

/** Satélites: etiqueta, anillo y ángulo inicial (grados, 0 = arriba). */
const SATELLITES: { label: (typeof ORBIT_LABELS)[number]; ring: 0 | 1 | 2; angle: number; tone: string }[] = [
  { label: "Retos y XP", ring: 0, angle: 55, tone: "bg-primary text-white" },
  { label: "Mentorías", ring: 1, angle: -48, tone: "bg-white text-navy-950" },
  { label: "Comunidad", ring: 1, angle: 140, tone: "bg-white/12 text-white ring-1 ring-white/30 backdrop-blur-sm" },
  { label: "Coach IA", ring: 2, angle: 220, tone: "bg-accent-bright text-on-accent" },
  { label: "Capacitaciones", ring: 2, angle: 28, tone: "bg-white/12 text-white ring-1 ring-white/30 backdrop-blur-sm" },
];

/** Estrellas con posición fija (semilla): iguales en servidor y cliente. */
const STARS = (() => {
  const rnd = createSeededRandom(7);
  return Array.from({ length: 42 }, () => ({ x: rnd(0, 600), y: rnd(0, 600), r: rnd(6, 20) / 10 }));
})();

/**
 * Sistema orbital del hero: el núcleo «Tu idea» (arrastrable), tres anillos, satélites con lo que
 * da el CIE-U y un campo de estrellas. Solo marcado: las animaciones están en `hero.tsx`.
 */
export function OrbitSystem() {
  return (
    <div className="orbit-stage relative mx-auto aspect-square w-full max-w-[580px] select-none" data-reveal>
      <svg aria-hidden="true" viewBox="0 0 600 600" className="absolute inset-0 size-full overflow-visible">
        <g className="orbit-stars">
          {STARS.map((s, i) => (
            <circle key={i} className="star" cx={s.x.toFixed(1)} cy={s.y.toFixed(1)} r={s.r} fill="white" opacity=".35" />
          ))}
        </g>
        {RINGS.map((ring) => (
          <circle
            key={ring.r}
            className="orbit-ring"
            cx="300"
            cy="300"
            r={ring.r}
            fill="none"
            stroke="currentColor"
            strokeOpacity={ring.dashed ? 0.35 : 0.2}
            strokeWidth="1.5"
            strokeDasharray={ring.dashed ? "4 9" : undefined}
          />
        ))}
      </svg>

      {/* Satélites: el brazo gira y la etiqueta contrarrota para quedar derecha. */}
      <div className="orbit-sats absolute inset-0">
        {SATELLITES.map((s) => {
          const r = RINGS[s.ring].r;
          return (
            <div
              key={s.label}
              className="orbit-arm pointer-events-none absolute inset-0"
              data-angle={s.angle}
              data-period={RINGS[s.ring].period}
              style={{ transform: `rotate(${s.angle}deg)` }}
            >
              <div className="absolute left-1/2" style={{ top: `${50 - (r / 600) * 100}%` }}>
                <span
                  className={`orbit-label sat inline-flex -translate-x-1/2 -translate-y-1/2 items-center rounded-full px-3.5 py-2 text-[13px] font-bold whitespace-nowrap shadow-[0_10px_30px_-12px_rgb(0_0_0/.6)] sm:text-sm ${s.tone}`}
                  style={{ transform: `rotate(${-s.angle}deg)` }}
                >
                  {s.label}
                </span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Núcleo: la idea. En escritorio se puede arrastrar y vuelve con un rebote. */}
      <div className="absolute top-1/2 left-1/2 size-[30%] -translate-x-1/2 -translate-y-1/2">
        <div className="orbit-core-drag relative size-full md:cursor-grab md:active:cursor-grabbing">
          <span aria-hidden="true" className="orbit-halo absolute inset-0 rounded-full bg-primary/40" />
          <span className="orbit-core relative flex size-full flex-col items-center justify-center rounded-full bg-primary text-center text-white shadow-[0_0_90px_-8px_var(--primary)]">
            <span className="font-heading text-[clamp(15px,2.4vw,22px)] leading-tight font-bold">Tu idea</span>
            <span className="orbit-hint mt-1 hidden text-[11px] font-semibold text-white/70 md:block">arrástrala</span>
          </span>
        </div>
      </div>
    </div>
  );
}
