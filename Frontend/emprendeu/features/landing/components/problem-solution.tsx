"use client";

import Link from "next/link";
import { animate, createSeededRandom, createTimeline, onScroll, stagger, utils } from "animejs";
import { Bot, GraduationCap, Route, Trophy, UserCheck, Users, type LucideIcon } from "lucide-react";

import { CTA, PROBLEMS, type ProblemIcon } from "../content";
import { part, useAnimeScope } from "../hooks/use-anime-scope";
import { Container, SectionHeading } from "./primitives";

const ICONS: Record<ProblemIcon, LucideIcon> = {
  route: Route,
  mentor: UserCheck,
  bot: Bot,
  trophy: Trophy,
  cap: GraduationCap,
  people: Users,
};

/** Inclinación de cada nota (semilla fija: igual en servidor y cliente). */
const TILT = (() => {
  const rnd = createSeededRandom(21);
  return PROBLEMS.map(() => ({ rotate: rnd(-9, 9), drift: rnd(-120, 120) }));
})();

const css = (root: HTMLElement, name: string) => getComputedStyle(root).getPropertyValue(name).trim();

/**
 * «El problema» y «El giro», en una sola escena fijada (escritorio, con movimiento). Es el único
 * momento grande de la página:
 * 1) caen las notas con lo que frena a quien emprende y la idea se apaga;
 * 2) el fondo pasa de tinta a azul y la idea se reenciende;
 * 3) cada nota se voltea y muestra lo que el CIE-U pone para resolverlo.
 * En móvil, sin movimiento o sin JS se ve la lista de pares problema → respuesta.
 */
export function ProblemSolution() {
  const ref = useAnimeScope<HTMLElement>(
    (_reduced, root) => {
      // La escena fijada debe estar visible antes de que onScroll mida su tamaño.
      root.setAttribute("data-anim", "on");

      // Lista (móvil): cada par se revela al entrar.
      const list = root.querySelector<HTMLElement>(".ps-list");
      if (list) {
        utils.set(part("pair"), { opacity: 0, y: 24 });
        utils.set(part("pair-answer"), { opacity: 0, x: -16 });
        const enter = () => onScroll({ target: list, enter: "end start+=80", repeat: false });
        animate(part("pair"), { opacity: 1, y: 0, duration: 700, delay: stagger(110), ease: "out(4)", autoplay: enter() });
        animate(part("pair-answer"), {
          opacity: 1,
          x: 0,
          duration: 600,
          delay: stagger(110, { start: 450 }),
          ease: "out(3)",
          autoplay: enter(),
        });
      }

      // Escena fijada (escritorio).
      const pinned = root.querySelector<HTMLElement>(".ps-pinned");
      if (!pinned) return;
      const notes = root.querySelectorAll<HTMLElement>(part("note"));
      notes.forEach((note, i) => {
        utils.set(note, { y: "-110vh", x: TILT[i].drift, rotate: TILT[i].rotate * 3, opacity: 0 });
      });
      utils.set(part("note-inner"), { rotateY: 0 });
      utils.set(part("title-b"), { opacity: 0, y: 40 });
      utils.set(part("sub-b"), { opacity: 0 });
      utils.set(part("bg"), { backgroundColor: css(root, "--foreground") });

      const tl = createTimeline({
        defaults: { ease: "linear" },
        autoplay: onScroll({ target: pinned, enter: "start start", leave: "end end", sync: 0.5 }),
      });

      // 1) Caen las notas (0–380) y la idea se apaga y tiembla.
      notes.forEach((note, i) => {
        tl.add(note, { y: 0, x: 0, rotate: TILT[i].rotate, opacity: 1, duration: 170, ease: "outBounce" }, 30 + i * 55);
      });
      tl.add(part("bulb-glow"), { scale: [1, 0.35], opacity: [1, 0.15], duration: 360 }, 0)
        .add(part("bulb"), { scale: [1, 0.8], duration: 360 }, 0)
        .add(part("bulb"), { x: [0, -6, 6, -4, 4, 0], duration: 80 }, 360)
        .add(part("bulb-label"), { opacity: [1, 0.4], duration: 300 }, 0);

      // 2) El giro: cambia el fondo, el título y la idea se reenciende (450–560).
      tl.add(part("bg"), { backgroundColor: css(root, "--primary"), duration: 110 }, 460)
        .add(part("title-a"), { opacity: 0, y: -40, duration: 70 }, 450)
        .add(part("sub-a"), { opacity: 0, duration: 60 }, 450)
        .add(part("title-b"), { opacity: 1, y: 0, duration: 90, ease: "out(3)" }, 500)
        .add(part("sub-b"), { opacity: 1, duration: 80 }, 530)
        .add(part("bulb"), { scale: 1.15, duration: 110, ease: "outBack(3)" }, 480)
        .add(part("bulb-glow"), { scale: 1.6, opacity: 1, duration: 140, ease: "out(3)" }, 480)
        .add(part("bulb-label"), { opacity: 1, duration: 60 }, 500)
        .add(part("bulb-ring"), { scale: [0.6, 2.4], opacity: [0.8, 0], duration: 160, ease: "out(2)" }, 490);

      // 3) Las notas se voltean y se enderezan (580–960).
      notes.forEach((note, i) => {
        const inner = note.querySelector<HTMLElement>(part("note-inner"));
        if (inner) tl.add(inner, { rotateY: 180, duration: 120, ease: "inOut(3)" }, 590 + i * 60);
        tl.add(note, { rotate: 0, duration: 120, ease: "out(3)" }, 590 + i * 60);
      });
      tl.add(part("ps-cta"), { opacity: [0, 1], y: [20, 0], duration: 60 }, 940);
    },
    { lazy: false },
  );

  return (
    <section ref={ref} data-anim="pending" id="problema" aria-labelledby="problema-title" className="ps relative scroll-mt-16">
      {/* Lista legible: móvil, movimiento reducido o sin JavaScript. */}
      <div className="ps-list bg-foreground py-24 text-white">
        <Container>
          <SectionHeading id="problema-title" className="max-w-[18ch]">
            Casi ninguna idea muere por mala. Muere por quedarse sola.
          </SectionHeading>
          <p className="mt-5 max-w-[52ch] text-lg leading-relaxed text-on-navy-muted">
            Esto es lo que frena a la mayoría. Y esto es lo que el CIE-U pone para que no te pase.
          </p>
          <ul className="mt-12 grid gap-4 md:grid-cols-2">
            {PROBLEMS.map((p) => {
              const Icon = ICONS[p.icon];
              return (
                <li key={p.problem} data-part="pair" className="rounded-2xl bg-white/[.06] p-5 ring-1 ring-white/10">
                  <p className="text-[17px] text-on-navy-muted line-through decoration-accent-bright decoration-2">«{p.problem}»</p>
                  <p data-part="pair-answer" className="mt-3 flex items-start gap-3 text-lg font-semibold">
                    <span className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary">
                      <Icon aria-hidden="true" className="size-5" />
                    </span>
                    {p.answer}
                  </p>
                </li>
              );
            })}
          </ul>
        </Container>
      </div>

      {/* Escena fijada (solo escritorio con movimiento). */}
      <div aria-hidden="true" className="ps-pinned hidden h-[220vh]">
        <div data-part="bg" className="sticky top-0 h-screen overflow-hidden text-white">
          <Container className="grid h-full grid-cols-[0.9fr_1.1fr] items-center gap-10">
            <div className="relative">
              <div className="relative min-h-[260px]">
                <p data-part="title-a" className="absolute inset-x-0 top-0 font-heading text-[clamp(40px,4.6vw,64px)] leading-[1.02] font-bold tracking-[-.03em]">
                  Casi ninguna idea muere por mala. Muere por quedarse sola.
                </p>
                <p data-part="title-b" className="absolute inset-x-0 top-0 font-heading text-[clamp(44px,5.4vw,76px)] leading-[1] font-bold tracking-[-.035em]">
                  Por eso existe el <span className="whitespace-nowrap">CIE-U.</span>
                </p>
              </div>
              <div className="relative mt-6 min-h-[84px] max-w-[42ch] text-lg leading-relaxed">
                <p data-part="sub-a" className="absolute inset-0 text-on-navy-muted">
                  Sigue bajando: estas son las frases que más se escuchan cuando un proyecto se queda a medias.
                </p>
                <p data-part="sub-b" className="absolute inset-0 text-white">
                  Cada problema tiene una respuesta concreta dentro del programa. Gratis para estudiantes de la UAGRM.
                </p>
              </div>
              <Link
                href="/apply"
                tabIndex={-1}
                data-part="ps-cta"
                className="mt-8 inline-flex min-h-14 items-center rounded-xl bg-white px-7 text-base font-bold text-primary opacity-0"
              >
                {CTA.apply}
              </Link>
            </div>

            <div className="relative">
              {/* La idea: se apaga cuando caen las notas y se reenciende con el giro. */}
              <div data-part="bulb" className="absolute top-1/2 left-1/2 flex size-40 -translate-x-1/2 -translate-y-1/2 items-center justify-center">
                <span data-part="bulb-glow" className="landing-glow absolute -inset-32 [--glow:var(--accent-bright)] [--glow-strength:55%]" />
                <span data-part="bulb-ring" className="absolute inset-0 rounded-full border-4 border-white opacity-0" />
                <span className="relative flex size-full items-center justify-center rounded-full bg-accent-bright text-on-accent shadow-glow-bulb">
                  <span data-part="bulb-label" className="font-heading text-xl font-bold">
                    tu idea
                  </span>
                </span>
              </div>

              <ul className="relative z-10 grid grid-cols-2 gap-4 [perspective:1200px]">
                {PROBLEMS.map((p, i) => {
                  const Icon = ICONS[p.icon];
                  return (
                    <li key={p.problem} data-part="note" className={`h-[132px] ${i % 2 ? "translate-y-6" : ""}`}>
                      <div data-part="note-inner" className="relative size-full [transform-style:preserve-3d]">
                        <div className="absolute inset-0 flex items-center rounded-xl bg-warning-soft p-5 text-[17px] leading-snug font-semibold text-warning-foreground shadow-note [backface-visibility:hidden]">
                          «{p.problem}»
                        </div>
                        <div className="absolute inset-0 flex [transform:rotateY(180deg)] flex-col justify-center gap-2.5 rounded-xl bg-white p-5 text-navy-950 shadow-card-deep [backface-visibility:hidden]">
                          <span className="flex size-9 items-center justify-center rounded-lg bg-primary text-white">
                            <Icon className="size-5" />
                          </span>
                          <span className="text-[16px] leading-snug font-bold">{p.answer}</span>
                        </div>
                      </div>
                    </li>
                  );
                })}
              </ul>
            </div>
          </Container>
        </div>
      </div>
    </section>
  );
}
