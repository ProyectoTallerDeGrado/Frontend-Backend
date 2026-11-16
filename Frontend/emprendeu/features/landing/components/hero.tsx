"use client";

import { animate, createTimeline, scrambleText, stagger, svg, utils } from "animejs";

import { APP_DOWNLOAD_URL, CTA, HERO_WORDS } from "../content";
import { part, useAnimeScope } from "../hooks/use-anime-scope";
import { ambient, motionPaused } from "../stores/motion-store";
import { OrbitSystem } from "./orbit-system";
import { Container, delay, LandingButton } from "./primitives";

/**
 * Hero. El titular, el texto y los botones entran con CSS (`.landing-rise`): están en el HTML y se
 * ven antes de que cargue el JavaScript. anime.js solo arma la órbita y cambia la palabra del
 * titular; ambas cosas se detienen con «Pausar animaciones» y la palabra también al pasar el cursor.
 */
export function Hero() {
  const ref = useAnimeScope<HTMLElement>(
    (_reduced, root) => {
      const cleanups: (() => void)[] = [];
      const rings = svg.createDrawable(part("orbit-ring"));

      utils.set(rings, { draw: "0 0" });
      utils.set(part("orbit-core"), { scale: 0 });
      utils.set(part("orbit-halo"), { opacity: 0 });
      utils.set(part("sat"), { opacity: 0, scale: 0.4 });
      utils.set(part("star"), { opacity: 0 });

      createTimeline({ defaults: { ease: "out(4)" } })
        .add(rings, { draw: "0 1", duration: 1400, delay: stagger(180), ease: "inOut(3)" }, 150)
        .add(part("orbit-core"), { scale: 1, duration: 1000, ease: "outElastic(1, .6)" }, 350)
        .add(part("sat"), { opacity: 1, scale: 1, duration: 600, delay: stagger(110), ease: "outBack(2)" }, 800)
        .add(part("star"), { opacity: [0, 0.45], duration: 900, delay: stagger(16, { from: "center" }) }, 500);

      // Órbitas lentas: cada anillo a su velocidad; la etiqueta contrarrota para quedar derecha.
      const loops: { pause: () => unknown; resume: () => unknown }[] = [];
      root.querySelectorAll<HTMLElement>(part("orbit-arm")).forEach((arm) => {
        const angle = Number(arm.dataset.angle);
        const period = Number(arm.dataset.period);
        loops.push(animate(arm, { rotate: [angle, angle + 360], duration: period, ease: "linear", loop: true }));
        const label = arm.querySelector<HTMLElement>(part("orbit-label"));
        if (label) loops.push(animate(label, { rotate: [-angle, -angle - 360], duration: period, ease: "linear", loop: true }));
      });
      loops.push(animate(part("orbit-halo"), { scale: [1, 1.5], opacity: [0.5, 0], duration: 3200, ease: "out(2)", loop: true, delay: 1600 }));
      cleanups.push(ambient(loops));

      // La palabra del titular cambia sola: idea → app → tienda → marca → startup.
      const word = root.querySelector<HTMLElement>(part("hero-word-text"));
      const title = root.querySelector<HTMLElement>("#hero-title");
      if (word && title) {
        let index = 0;
        let held = false;
        const hold = () => (held = true);
        const release = () => (held = false);
        title.addEventListener("pointerenter", hold);
        title.addEventListener("pointerleave", release);
        const timer = window.setInterval(() => {
          if (held || motionPaused() || document.hidden || root.getBoundingClientRect().bottom < 0) return;
          index = (index + 1) % HERO_WORDS.length;
          animate(word, { innerHTML: scrambleText({ text: HERO_WORDS[index], chars: "a-z" }), duration: 900 });
        }, 3200);
        cleanups.push(() => {
          window.clearInterval(timer);
          title.removeEventListener("pointerenter", hold);
          title.removeEventListener("pointerleave", release);
        });
      }

      return () => cleanups.forEach((c) => c());
    },
    { lazy: false },
  );

  return (
    <section ref={ref} data-anim="pending" aria-labelledby="hero-title" className="relative isolate overflow-hidden bg-navy-950 text-white">
      <div aria-hidden="true" className="landing-glow absolute top-[8%] right-[-18%] -z-10 size-[min(900px,120vw)] [--glow-strength:38%]" />
      <Container className="grid min-h-[100svh] items-center gap-10 pt-28 pb-16 lg:grid-cols-[1.1fr_1fr] lg:gap-4 lg:pt-24">
        <div>
          <h1 id="hero-title" className="font-heading text-[clamp(46px,7.2vw,96px)] leading-[0.98] font-bold tracking-[-.035em]">
            <span className="sr-only">Tu idea no debería morir en un cuaderno.</span>
            <span aria-hidden="true" className="block">
              <span className="landing-rise inline-block">Tu</span>{" "}
              <span className="landing-pop inline-block rounded-xl bg-accent-bright px-3 pb-1 text-on-accent" style={delay(180)}>
                <span data-part="hero-word-text">idea</span>
              </span>
              <span className="landing-rise block" style={delay(90)}>
                no debería morir en un cuaderno.
              </span>
            </span>
          </h1>
          <p className="landing-rise mt-7 max-w-[36ch] text-[clamp(17px,1.6vw,20px)] leading-relaxed text-on-navy-muted" style={delay(260)}>
            El Centro de Innovación y Emprendimiento Universitario de la UAGRM te acompaña de la primera idea a un
            negocio que camina solo. Gratis.
          </p>
          <div className="landing-rise mt-9 flex flex-wrap items-center gap-3" style={delay(340)}>
            <LandingButton href="/apply">{CTA.apply}</LandingButton>
            <LandingButton href="#problema" variant="ghost" className="px-5">
              {CTA.howItWorks}
            </LandingButton>
          </div>
          <p className="landing-rise mt-10 text-sm text-on-navy-faint" style={delay(420)}>
            ¿Ya estás en el programa?{" "}
            {APP_DOWNLOAD_URL ? (
              <a href={APP_DOWNLOAD_URL} className="font-semibold text-white underline-offset-4 hover:underline">
                Descarga la app del emprendedor
              </a>
            ) : (
              <span className="font-semibold text-white">Entra desde la app del emprendedor en tu celular.</span>
            )}
          </p>
        </div>
        {/* Margen lateral en pantallas chicas: las etiquetas del anillo exterior no se cortan en el borde. */}
        <div className="relative px-7 text-on-navy-dim sm:px-0">
          <OrbitSystem />
        </div>
      </Container>
    </section>
  );
}
