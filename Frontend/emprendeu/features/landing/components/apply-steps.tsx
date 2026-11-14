"use client";

import Link from "next/link";
import { createTimeline, onScroll, stagger, utils } from "animejs";

import { APPLY_STEPS } from "../content";
import { useAnimeScope } from "../hooks/use-anime-scope";

/** «Cómo postular»: tres pasos; al entrar en pantalla la línea los une y los números aparecen en orden. */
export function ApplySteps() {
  const ref = useAnimeScope<HTMLElement>((_reduced, root) => {
    utils.set(".step-line", { scaleX: 0 });
    utils.set(".step-line-v", { scaleY: 0 });
    utils.set(".step-num", { scale: 0 });
    utils.set(".step-body", { opacity: 0, y: 16 });
    createTimeline({
      defaults: { ease: "out(4)" },
      autoplay: onScroll({ target: root.querySelector<HTMLElement>(".steps")!, enter: "end start+=100", repeat: false }),
    })
      .add([".step-line", ".step-line-v"], { scaleX: 1, scaleY: 1, duration: 1400, ease: "inOut(3)" }, 0)
      .add(".step-num", { scale: 1, duration: 700, delay: stagger(380), ease: "outBack(2.5)" }, 0)
      .add(".step-body", { opacity: 1, y: 0, duration: 700, delay: stagger(380) }, 120);
  });

  return (
    <section ref={ref} data-anim="pending" id="postular" aria-labelledby="postular-title" className="scroll-mt-20 bg-background py-24 sm:py-32">
      <div className="mx-auto max-w-[1240px] px-5 sm:px-8">
        <div className="flex flex-wrap items-end justify-between gap-6">
          <h2 id="postular-title" className="max-w-[14ch] font-heading text-[clamp(36px,5vw,64px)] leading-[1.02] font-bold tracking-[-.03em] text-balance">
            Postular es sencillo.
          </h2>
          <Link
            href="/apply"
            className="inline-flex min-h-14 items-center rounded-2xl bg-primary px-7 text-base font-bold text-white outline-none transition-[transform,background] duration-200 hover:-translate-y-0.5 hover:bg-primary-hover focus-visible:ring-4 focus-visible:ring-primary/30"
          >
            Empezar mi postulación
          </Link>
        </div>

        <ol className="steps relative mt-16 grid gap-12 md:grid-cols-3 md:gap-8">
          <span aria-hidden="true" className="step-line absolute top-7 right-[16%] left-[16%] hidden h-1 origin-left rounded-full bg-primary md:block" />
          <span aria-hidden="true" className="step-line-v absolute top-4 bottom-4 left-[26px] w-1 origin-top rounded-full bg-primary md:hidden" />
          {APPLY_STEPS.map((step, i) => (
            <li key={step.title} className="relative flex gap-5 md:flex-col md:items-center md:text-center">
              <span
                aria-hidden="true"
                className="step-num relative z-10 flex size-14 shrink-0 items-center justify-center rounded-full bg-navy-950 font-heading text-xl font-bold text-white ring-8 ring-background"
              >
                {i + 1}
              </span>
              <div className="step-body md:mt-6">
                <h3 className="font-heading text-2xl font-bold tracking-[-.02em]">{step.title}</h3>
                <p className="mt-2 max-w-[32ch] text-[16px] leading-relaxed text-muted-foreground">{step.text}</p>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
