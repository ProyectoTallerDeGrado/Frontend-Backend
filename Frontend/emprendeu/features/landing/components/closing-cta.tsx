"use client";

import Link from "next/link";
import { Rocket } from "lucide-react";
import { animate, createAnimatable, onScroll, splitText, stagger, utils } from "animejs";

import { useAnimeScope } from "../hooks/use-anime-scope";

/**
 * Clímax: titular que entra palabra por palabra, botón magnético (sigue al cursor cuando se acerca)
 * y un cohete que despega al pasar sobre el botón. Órbita de fondo con CSS.
 */
export function ClosingCta() {
  const ref = useAnimeScope<HTMLElement>((_reduced, root) => {
    const { words } = splitText(root.querySelector<HTMLElement>(".cta-title")!, { words: { wrap: "clip" } });
    utils.set(words, { y: "110%" });
    utils.set(".cta-fade", { opacity: 0, y: 16 });
    const enter = () => onScroll({ target: root, enter: "end start+=180", repeat: false });
    animate(words, { y: "0%", duration: 900, delay: stagger(70), ease: "out(4)", autoplay: enter() });
    animate(".cta-fade", { opacity: 1, y: 0, duration: 700, delay: stagger(120, { start: 500 }), ease: "out(3)", autoplay: enter() });

    if (!window.matchMedia("(pointer: fine)").matches) return;

    // Botón magnético.
    const zone = root.querySelector<HTMLElement>(".magnet-zone")!;
    const button = root.querySelector<HTMLElement>(".magnet")!;
    const pull = createAnimatable(button, { x: 500, y: 500, ease: "out(3)" });
    const onMove = (e: PointerEvent) => {
      const b = zone.getBoundingClientRect();
      pull.x((e.clientX - (b.left + b.width / 2)) * 0.35);
      pull.y((e.clientY - (b.top + b.height / 2)) * 0.35);
    };
    const onLeave = () => {
      pull.x(0);
      pull.y(0);
    };
    zone.addEventListener("pointermove", onMove);
    zone.addEventListener("pointerleave", onLeave);

    // El cohete despega y vuelve.
    const rocket = root.querySelector<HTMLElement>(".cta-rocket")!;
    const launch = () =>
      animate(rocket, {
        keyframes: [
          { x: -2, y: 2, duration: 80 },
          { x: 2, y: -2, duration: 80 },
          { x: 46, y: -46, opacity: 0, duration: 380, ease: "in(3)" },
          { x: -30, y: 30, duration: 0 },
          { x: 0, y: 0, opacity: 1, duration: 420, ease: "out(3)" },
        ],
      });
    button.addEventListener("pointerenter", launch);
    return () => {
      zone.removeEventListener("pointermove", onMove);
      zone.removeEventListener("pointerleave", onLeave);
      button.removeEventListener("pointerenter", launch);
    };
  });

  return (
    <section ref={ref} data-anim="pending" aria-labelledby="cierre-title" className="relative isolate overflow-hidden bg-navy-950 py-28 text-white sm:py-40">
      <svg
        aria-hidden="true"
        viewBox="0 0 600 600"
        className="absolute top-1/2 right-[-200px] -z-10 size-[760px] -translate-y-1/2 text-on-navy-dim opacity-60 sm:right-[-80px]"
      >
        <g className="origin-center animate-[orbit-spin_80s_linear_infinite] [transform-box:fill-box]">
          <circle cx="300" cy="300" r="270" fill="none" stroke="currentColor" strokeOpacity=".25" strokeWidth="1.5" />
          <circle cx="300" cy="30" r="7" fill="var(--accent-bright)" />
        </g>
        <g className="origin-center animate-[orbit-spin-reverse_50s_linear_infinite] [transform-box:fill-box]">
          <circle cx="300" cy="300" r="180" fill="none" stroke="currentColor" strokeOpacity=".35" strokeWidth="1.5" strokeDasharray="4 9" />
          <circle cx="480" cy="300" r="5" fill="white" />
        </g>
        <circle cx="300" cy="300" r="70" fill="var(--primary)" fillOpacity=".5" className="origin-center animate-[core-pulse_4s_ease-in-out_infinite] [transform-box:fill-box]" />
      </svg>
      <div className="mx-auto max-w-[1240px] px-5 sm:px-8">
        <h2 id="cierre-title" className="cta-title max-w-[14ch] font-heading text-[clamp(44px,7vw,96px)] leading-[0.98] font-bold tracking-[-.035em] text-balance">
          Tu idea ya tiene órbita. Falta que despegue.
        </h2>
        <p className="cta-fade mt-7 max-w-[44ch] text-lg leading-relaxed text-on-navy-muted">
          Es gratis y es para estudiantes de la UAGRM. Si tu idea todavía es pequeña, mejor: para eso es la
          preincubación.
        </p>
        <div className="cta-fade magnet-zone -m-10 mt-0 inline-block p-10">
          <Link
            href="/apply"
            className="magnet inline-flex min-h-16 items-center gap-3 rounded-2xl bg-accent-bright px-9 text-lg font-bold text-on-accent shadow-[0_22px_50px_-16px_var(--accent-bright)] outline-none focus-visible:ring-4 focus-visible:ring-white/50"
          >
            <span className="cta-rocket inline-flex">
              <Rocket aria-hidden="true" className="size-6" />
            </span>
            Postula tu emprendimiento
          </Link>
        </div>
      </div>
    </section>
  );
}
