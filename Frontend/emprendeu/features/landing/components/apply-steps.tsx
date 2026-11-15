"use client";

import { createTimeline, onScroll, stagger, utils } from "animejs";

import { APPLY_STEPS, CTA } from "../content";
import { part, useAnimeScope } from "../hooks/use-anime-scope";
import { Container, LandingButton, SectionHeading } from "./primitives";

/** «Cómo postular»: tres pasos (una secuencia real); al entrar en pantalla la línea los une en orden. */
export function ApplySteps() {
  const ref = useAnimeScope<HTMLElement>((_reduced, root) => {
    const steps = root.querySelector<HTMLElement>(part("steps"));
    if (!steps) return;
    utils.set(part("step-line"), { scaleX: 0 });
    utils.set(part("step-line-v"), { scaleY: 0 });
    utils.set(part("step-num"), { scale: 0 });
    utils.set(part("step-body"), { opacity: 0, y: 16 });
    createTimeline({
      defaults: { ease: "out(4)" },
      autoplay: onScroll({ target: steps, enter: "end start+=100", repeat: false }),
    })
      .add([part("step-line"), part("step-line-v")], { scaleX: 1, scaleY: 1, duration: 1400, ease: "inOut(3)" }, 0)
      .add(part("step-num"), { scale: 1, duration: 700, delay: stagger(380), ease: "outBack(2.5)" }, 0)
      .add(part("step-body"), { opacity: 1, y: 0, duration: 700, delay: stagger(380) }, 120);
  });

  return (
    <section ref={ref} data-anim="pending" id="postular" aria-labelledby="postular-title" className="scroll-mt-20 bg-background py-24 sm:py-32">
      <Container>
        <div className="flex flex-wrap items-end justify-between gap-6">
          <SectionHeading id="postular-title" className="max-w-[14ch]">
            Postular es sencillo.
          </SectionHeading>
          <LandingButton href="/apply" variant="primary">
            {CTA.apply}
          </LandingButton>
        </div>

        <ol data-part="steps" className="relative mt-16 grid gap-12 md:grid-cols-3 md:gap-8">
          <span aria-hidden="true" data-part="step-line" className="absolute top-7 right-[16%] left-[16%] hidden h-1 origin-left rounded-full bg-primary md:block" />
          <span aria-hidden="true" data-part="step-line-v" className="absolute top-4 bottom-4 left-[26px] w-1 origin-top rounded-full bg-primary md:hidden" />
          {APPLY_STEPS.map((step, i) => (
            <li key={step.title} className="relative flex gap-5 md:flex-col md:items-center md:text-center">
              <span
                aria-hidden="true"
                data-part="step-num"
                className="relative z-10 flex size-14 shrink-0 items-center justify-center rounded-full bg-navy-950 font-heading text-xl font-bold text-white ring-8 ring-background"
              >
                {i + 1}
              </span>
              <div data-part="step-body" className="md:mt-6">
                <h3 className="font-heading text-2xl font-bold tracking-[-.02em]">{step.title}</h3>
                <p className="mt-2 max-w-[32ch] text-[16px] leading-relaxed text-muted-foreground">{step.text}</p>
              </div>
            </li>
          ))}
        </ol>
      </Container>
    </section>
  );
}
