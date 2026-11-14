"use client";

import { createTimeline, onScroll, stagger, svg, utils } from "animejs";

import { Flag, Lightbulb, Rocket, Wrench, type LucideIcon } from "lucide-react";

import { STAGES } from "../content";
import { useAnimeScope } from "../hooks/use-anime-scope";

/** Puntos de cada etapa en el viewBox 1200 × 340 (coinciden con el centro de cada columna). */
const POINTS = [
  [150, 250],
  [450, 100],
  [750, 250],
  [1050, 100],
] as const;
const STAGE_ICONS: LucideIcon[] = [Lightbulb, Wrench, Rocket, Flag];
const PATH = "M150 250 C300 250 300 100 450 100 C600 100 600 250 750 250 C900 250 900 100 1050 100";

/**
 * «El camino»: las cuatro etapas del programa. En escritorio la ruta se dibuja al ritmo del
 * scroll y un punto la recorre; en móvil, una línea vertical crece y los nodos se encienden.
 */
export function JourneySection() {
  const ref = useAnimeScope<HTMLElement>((_reduced, root) => {
    const [path] = svg.createDrawable(".journey-path");
    utils.set(path, { draw: "0 0" });
    utils.set(".journey-node", { scale: 0.3, opacity: 0.35 });
    utils.set(".journey-stage", { opacity: 0.3, y: 14 });
    utils.set(".journey-line-fill", { scaleY: 0 });
    utils.set([".journey-trail", ".journey-comet"], { x: 150, y: 250 });
    utils.set(".journey-dot-m", { scale: 0.3, opacity: 0.35 });

    // Escritorio: ruta + cometa sincronizados con el scroll.
    const tl = createTimeline({
      defaults: { ease: "linear" },
      autoplay: onScroll({ target: root.querySelector(".journey-track")!, enter: "end start", leave: "center end", sync: 0.35 }),
    });
    tl.add(path, { draw: "0 1", duration: 1000 }, 0).add(
      ".journey-comet",
      { ...svg.createMotionPath(".journey-path"), duration: 1000 },
      0,
    );
    // Estela: cuatro chispas que siguen al cometa con un poco de retraso.
    root.querySelectorAll(".journey-trail").forEach((spark, i) => {
      tl.add(spark, { ...svg.createMotionPath(".journey-path"), duration: 1000 }, (i + 1) * 22);
    });
    POINTS.forEach((_, i) => {
      const at = Math.min(980, i * 330);
      tl.add(`.journey-node-${i}`, { scale: 1, opacity: 1, duration: 60, ease: "outBack(3)" }, at).add(
        `.journey-stage-${i}`,
        { opacity: 1, y: 0, duration: 80, ease: "out(2)" },
        at,
      );
    });

    // Móvil: la línea crece y cada etapa se enciende.
    createTimeline({
      defaults: { ease: "linear" },
      autoplay: onScroll({ target: root.querySelector(".journey-list")!, enter: "end start", leave: "center end", sync: 0.35 }),
    })
      .add(".journey-line-fill", { scaleY: 1, duration: 1000 }, 0)
      .add(".journey-dot-m", { scale: 1, opacity: 1, duration: 120, delay: stagger(280), ease: "outBack(3)" }, 0)
      .add(".journey-stage-m", { opacity: 1, y: 0, duration: 120, delay: stagger(280) }, 0);
  });

  return (
    <section ref={ref} data-anim="pending" id="camino" aria-labelledby="camino-title" className="scroll-mt-20 bg-background py-24 sm:py-32">
      <div className="mx-auto max-w-[1240px] px-5 sm:px-8">
        <h2 id="camino-title" className="max-w-[16ch] font-heading text-[clamp(36px,5vw,64px)] leading-[1.02] font-bold tracking-[-.03em] text-balance">
          Un camino en cuatro etapas.
        </h2>
        <p className="mt-5 max-w-[56ch] text-lg leading-relaxed text-muted-foreground">
          No avanzas solo ni a ciegas: cada etapa tiene retos claros, y la coordinación te pasa a la siguiente
          cuando tu emprendimiento está listo.
        </p>

        {/* Escritorio */}
        <div className="journey-track mt-16 hidden md:block">
          <svg aria-hidden="true" viewBox="0 0 1200 340" className="w-full overflow-visible">
            <path d={PATH} fill="none" stroke="var(--border-strong)" strokeWidth="3" strokeDasharray="2 10" strokeLinecap="round" />
            <path className="journey-path" d={PATH} fill="none" stroke="var(--primary)" strokeWidth="5" strokeLinecap="round" />
            {POINTS.map(([x, y], i) => (
              <g key={i} className={`journey-node journey-node-${i}`} style={{ transformOrigin: `${x}px ${y}px` }}>
                <circle cx={x} cy={y} r="30" fill="var(--card)" stroke="var(--primary)" strokeWidth="4" />
                <text
                  x={x}
                  y={y}
                  dy="0.35em"
                  textAnchor="middle"
                  className="fill-navy-950 font-heading text-[22px] font-bold"
                >
                  {i + 1}
                </text>
              </g>
            ))}
            {[0.5, 0.36, 0.24, 0.14].map((o, i) => (
              <circle key={i} className="journey-trail" r={7 - i * 1.3} fill="var(--accent-bright)" opacity={o} />
            ))}
            <g className="journey-comet">
              <circle r="22" fill="var(--accent-bright)" opacity=".18" />
              <circle r="9" fill="var(--accent-bright)" />
            </g>
          </svg>
          <ol className="mt-4 grid grid-cols-4 gap-8">
            {STAGES.map((s, i) => (
              <li key={s.name} className={`journey-stage journey-stage-${i}`}>
                {(() => {
                  const Icon = STAGE_ICONS[i];
                  return (
                    <span className="mb-4 flex size-12 items-center justify-center rounded-2xl bg-navy-950 text-white">
                      <Icon aria-hidden="true" className="size-6" />
                    </span>
                  );
                })()}
                <h3 className="font-heading text-2xl font-bold tracking-[-.02em]">{s.name}</h3>
                <p className="mt-2 text-[15px] leading-relaxed text-muted-foreground">{s.text}</p>
              </li>
            ))}
          </ol>
        </div>

        {/* Móvil */}
        <ol className="journey-list relative mt-12 flex flex-col gap-10 pl-14 md:hidden">
          <span aria-hidden="true" className="absolute top-2 bottom-2 left-[19px] w-1 rounded-full bg-border" />
          <span aria-hidden="true" className="journey-line-fill absolute top-2 bottom-2 left-[19px] w-1 origin-top rounded-full bg-primary" />
          {STAGES.map((s, i) => (
            <li key={s.name} className="relative">
              <span
                aria-hidden="true"
                className="journey-dot-m absolute top-0 -left-14 flex size-10 items-center justify-center rounded-full border-4 border-primary bg-card font-heading font-bold"
              >
                {i + 1}
              </span>
              <div className="journey-stage-m">
                <h3 className="font-heading text-xl font-bold">{s.name}</h3>
                <p className="mt-1.5 text-[15px] leading-relaxed text-muted-foreground">{s.text}</p>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
