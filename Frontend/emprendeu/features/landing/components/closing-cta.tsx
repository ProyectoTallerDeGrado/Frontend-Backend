import { CTA } from "../content";
import { Container, LandingButton } from "./primitives";

/**
 * Cierre: el mismo botón del hero, sin efectos. La órbita de fondo es CSS (giro muy lento) y se
 * detiene con «Pausar animaciones» (`.landing-ambient`) o con «reducir movimiento».
 */
export function ClosingCta() {
  return (
    <section aria-labelledby="cierre-title" className="relative isolate overflow-hidden bg-navy-950 py-28 text-white sm:py-40">
      <svg
        aria-hidden="true"
        viewBox="0 0 600 600"
        className="absolute top-1/2 right-[-200px] -z-10 size-[760px] -translate-y-1/2 text-on-navy-dim opacity-60 sm:right-[-80px]"
      >
        <g className="landing-ambient origin-center animate-[orbit-spin_120s_linear_infinite] [transform-box:fill-box]">
          <circle cx="300" cy="300" r="270" fill="none" stroke="currentColor" strokeOpacity=".25" strokeWidth="1.5" />
          <circle cx="300" cy="30" r="7" fill="var(--accent-bright)" />
        </g>
        <g className="landing-ambient origin-center animate-[orbit-spin-reverse_80s_linear_infinite] [transform-box:fill-box]">
          <circle cx="300" cy="300" r="180" fill="none" stroke="currentColor" strokeOpacity=".35" strokeWidth="1.5" strokeDasharray="4 9" />
          <circle cx="480" cy="300" r="5" fill="white" />
        </g>
        <circle cx="300" cy="300" r="70" fill="var(--primary)" fillOpacity=".5" />
      </svg>
      <Container>
        <h2 id="cierre-title" className="max-w-[14ch] font-heading text-[clamp(44px,7vw,96px)] leading-[0.98] font-bold tracking-[-.035em] text-balance">
          Tu idea ya tiene órbita. Falta que despegue.
        </h2>
        <p className="mt-7 max-w-[44ch] text-lg leading-relaxed text-on-navy-muted">
          Es gratis y es para estudiantes de la UAGRM. Si tu idea todavía es pequeña, mejor: para eso es la
          preincubación.
        </p>
        <LandingButton href="/apply" size="lg" className="mt-10">
          {CTA.apply}
        </LandingButton>
      </Container>
    </section>
  );
}
