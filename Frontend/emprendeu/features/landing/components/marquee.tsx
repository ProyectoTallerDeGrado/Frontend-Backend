"use client";

import { animate, createAnimatable, utils } from "animejs";

import { MARQUEE_WORDS } from "../content";
import { useAnimeScope } from "../hooks/use-anime-scope";

/**
 * Marquesina infinita bajo el hero. Avanza sola y, en escritorio, acelera con la velocidad del
 * scroll (y se inclina un poco); se pausa fuera de pantalla.
 */
export function Marquee() {
  const ref = useAnimeScope<HTMLDivElement>((_reduced, root) => {
    const track = root.querySelector<HTMLElement>(".marquee-track")!;
    const loop = animate(track, { x: ["0%", "-50%"], duration: 28000, ease: "linear", loop: true });

    const io = new IntersectionObserver(([entry]) => (entry.isIntersecting ? loop.play() : loop.pause()));
    io.observe(root);

    const skew = createAnimatable(root.querySelector(".marquee-skew")!, { skewX: 600, ease: "out(3)" });
    let last = window.scrollY;
    let lastT = performance.now();
    const onScroll = () => {
      const now = performance.now();
      const v = (window.scrollY - last) / Math.max(1, now - lastT); // px/ms
      last = window.scrollY;
      lastT = now;
      loop.speed = 1 + utils.clamp(Math.abs(v) * 4, 0, 6);
      skew.skewX(utils.clamp(-v * 6, -10, 10));
    };
    const settle = window.setInterval(() => {
      loop.speed += (1 - loop.speed) * 0.15;
      skew.skewX(0);
    }, 120);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      io.disconnect();
      window.clearInterval(settle);
      window.removeEventListener("scroll", onScroll);
    };
  });

  const words = [...MARQUEE_WORDS, ...MARQUEE_WORDS];
  return (
    <div ref={ref} data-anim="pending" aria-hidden="true" className="overflow-hidden border-y border-white/10 bg-navy-950 py-6 text-white">
      <div className="marquee-skew">
        <div className="marquee-track flex w-max">
          {words.map((w, i) => (
            <span key={i} className="flex items-center font-heading text-[clamp(28px,4vw,52px)] font-bold tracking-[-.02em]">
              <span className={i % 2 ? "text-transparent [-webkit-text-stroke:1.5px_var(--on-navy-dim)]" : "text-white"}>{w}</span>
              <span className="mx-8 inline-block size-3 rounded-full bg-accent-bright" />
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}
