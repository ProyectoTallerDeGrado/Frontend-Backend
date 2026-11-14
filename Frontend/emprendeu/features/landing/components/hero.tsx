"use client";

import Link from "next/link";
import {
  animate,
  createAnimatable,
  createDraggable,
  createTimeline,
  scrambleText,
  splitText,
  stagger,
  svg,
  utils,
} from "animejs";

import { HERO_WORDS } from "../content";
import { useAnimeScope } from "../hooks/use-anime-scope";
import { OrbitSystem } from "./orbit-system";

const desktop = () => window.matchMedia("(min-width: 768px) and (pointer: fine)").matches;

export function Hero({ signedIn }: { signedIn: boolean }) {
  const ref = useAnimeScope<HTMLElement>((_reduced, root) => {
    const cleanups: (() => void)[] = [];
    const { chars } = splitText(root.querySelectorAll(".hero-lines"), { chars: { wrap: "clip" } });
    const rings = svg.createDrawable(".orbit-ring");

    // Estados iniciales (síncronos) antes de mostrar la sección.
    utils.set(chars, { y: "115%", rotate: 8 });
    utils.set(".hero-word", { opacity: 0, scale: 0.6 });
    utils.set(".hero-fade", { opacity: 0, y: 18 });
    utils.set(rings, { draw: "0 0" });
    utils.set(".orbit-core", { scale: 0 });
    utils.set(".orbit-halo", { opacity: 0 });
    utils.set(".sat", { opacity: 0, scale: 0.4 });
    utils.set(".star", { opacity: 0 });

    createTimeline({ defaults: { ease: "out(4)" } })
      .add(chars, { y: "0%", rotate: 0, duration: 800, delay: stagger(22) }, 80)
      .add(".hero-word", { opacity: 1, scale: 1, duration: 900, ease: "outElastic(1, .5)" }, 320)
      .add(".hero-fade", { opacity: 1, y: 0, duration: 700, delay: stagger(110) }, 800)
      .add(rings, { draw: "0 1", duration: 1500, delay: stagger(200), ease: "inOut(3)" }, 200)
      .add(".orbit-core", { scale: 1, duration: 1100, ease: "outElastic(1, .55)" }, 500)
      .add(".sat", { opacity: 1, scale: 1, duration: 650, delay: stagger(120), ease: "outBack(2)" }, 1000)
      .add(".star", { opacity: [0, 0.6], duration: 900, delay: stagger(18, { from: "center" }) }, 600);

    // Las estrellas titilan.
    animate(".star", {
      opacity: () => [utils.random(15, 35) / 100, utils.random(60, 95) / 100],
      duration: () => utils.random(1400, 3200),
      delay: () => utils.random(1800, 4000),
      alternate: true,
      loop: true,
      ease: "inOut(2)",
    });

    // La palabra del titular cambia sola: idea → app → tienda → marca → startup.
    const word = root.querySelector<HTMLElement>(".hero-word-text")!;
    let index = 0;
    const timer = window.setInterval(() => {
      if (document.hidden || root.getBoundingClientRect().bottom < 0) return;
      index = (index + 1) % HERO_WORDS.length;
      animate(word, { innerHTML: scrambleText({ text: HERO_WORDS[index], chars: "a-z" }), duration: 900 });
    }, 2800);
    cleanups.push(() => window.clearInterval(timer));

    // Órbitas continuas: cada anillo a su velocidad; la etiqueta contrarrota.
    root.querySelectorAll<HTMLElement>(".orbit-arm").forEach((arm) => {
      const angle = Number(arm.dataset.angle);
      const period = Number(arm.dataset.period);
      animate(arm, { rotate: [angle, angle + 360], duration: period, ease: "linear", loop: true });
      animate(arm.querySelector(".orbit-label")!, { rotate: [-angle, -angle - 360], duration: period, ease: "linear", loop: true });
    });
    animate(".orbit-halo", { scale: [1, 1.6], opacity: [0.55, 0], duration: 2600, ease: "out(2)", loop: true, delay: 1600 });

    if (!desktop()) return () => cleanups.forEach((c) => c());

    // Parallax: la órbita sigue al puntero.
    const stage = root.querySelector<HTMLElement>(".orbit-stage")!;
    const follow = createAnimatable(stage, { x: 900, y: 900, ease: "out(3)" });
    const onMove = (e: PointerEvent) => {
      const box = root.getBoundingClientRect();
      follow.x(((e.clientX - box.left) / box.width - 0.5) * 36);
      follow.y(((e.clientY - box.top) / box.height - 0.5) * 28);
    };
    root.addEventListener("pointermove", onMove);
    cleanups.push(() => root.removeEventListener("pointermove", onMove));

    // El núcleo se arrastra; los satélites lo siguen a medias y, al soltarlo, todo vuelve con rebote.
    const sats = createAnimatable(".orbit-sats", { x: 500, y: 500, ease: "out(3)" });
    const core = createDraggable(".orbit-core-drag", {
      container: stage,
      containerPadding: 10,
      onGrab: () => animate(".orbit-hint", { opacity: 0, duration: 200 }),
      onDrag: (d) => {
        sats.x(d.x * 0.35);
        sats.y(d.y * 0.35);
      },
      onRelease: (d) => {
        d.stop();
        const p = { x: d.x, y: d.y };
        animate(p, {
          x: 0,
          y: 0,
          duration: 1500,
          ease: "outElastic(1, .35)",
          onUpdate: () => {
            d.setX(p.x, true).setY(p.y, true);
            sats.x(p.x * 0.35);
            sats.y(p.y * 0.35);
          },
        });
      },
    });
    cleanups.push(() => core.revert());
    return () => cleanups.forEach((c) => c());
  });

  return (
    <section
      ref={ref}
      data-anim="pending"
      aria-labelledby="hero-title"
      className="landing-hero relative isolate overflow-hidden bg-navy-950 text-white"
    >
      <div
        aria-hidden="true"
        className="absolute inset-0 -z-10 opacity-[.07] [background-image:radial-gradient(white_1px,transparent_1px)] [background-size:28px_28px] [mask-image:radial-gradient(ellipse_at_70%_45%,black,transparent_70%)]"
      />
      <div
        aria-hidden="true"
        className="absolute top-1/3 right-[-10%] -z-10 size-[620px] rounded-full bg-primary/25 blur-[120px]"
      />
      <div className="mx-auto grid min-h-[100svh] max-w-[1240px] items-center gap-10 px-5 pt-28 pb-16 sm:px-8 lg:grid-cols-[1.1fr_1fr] lg:gap-4 lg:pt-24">
        <div>
          <h1 id="hero-title" className="font-heading text-[clamp(46px,7.2vw,96px)] leading-[0.98] font-bold tracking-[-.035em]">
            <span className="sr-only">Tu idea no debería morir en un cuaderno.</span>
            <span aria-hidden="true" className="block" data-reveal>
              <span className="hero-lines">Tu </span>
              <span className="hero-word inline-block rounded-2xl bg-accent-bright px-3 pb-1 text-on-accent">
                <span className="hero-word-text">idea</span>
              </span>
              <span className="hero-lines block">no debería morir en un cuaderno.</span>
            </span>
          </h1>
          <p className="hero-fade mt-7 max-w-[36ch] text-[clamp(17px,1.6vw,20px)] leading-relaxed text-on-navy-muted" data-reveal>
            El Centro de Innovación y Emprendimiento Universitario de la UAGRM te acompaña de la primera idea a
            un negocio que camina solo. Gratis.
          </p>
          <div className="hero-fade mt-9 flex flex-wrap items-center gap-3" data-reveal>
            <Link
              href="/apply"
              className="inline-flex min-h-14 items-center gap-2 rounded-2xl bg-accent-bright px-7 text-base font-bold text-on-accent shadow-[0_18px_40px_-16px_var(--accent-bright)] outline-none transition-transform duration-200 hover:-translate-y-0.5 focus-visible:ring-4 focus-visible:ring-white/50"
            >
              Postula tu emprendimiento
            </Link>
            <a
              href="#problema"
              className="inline-flex min-h-14 items-center rounded-2xl px-5 text-base font-semibold text-white outline-none transition-colors hover:bg-white/10 focus-visible:ring-4 focus-visible:ring-white/40"
            >
              Ver cómo funciona
            </a>
          </div>
          <p className="hero-fade mt-10 text-sm text-on-navy-faint" data-reveal>
            {signedIn ? "Ya tienes sesión abierta." : "¿Eres parte del personal del CIE-U?"}{" "}
            <Link href={signedIn ? "/panel" : "/login"} className="font-semibold text-white underline-offset-4 hover:underline">
              {signedIn ? "Ir al panel" : "Ingresa al panel"}
            </Link>
          </p>
        </div>
        <div className="relative text-on-navy-dim">
          <OrbitSystem />
        </div>
      </div>
    </section>
  );
}
