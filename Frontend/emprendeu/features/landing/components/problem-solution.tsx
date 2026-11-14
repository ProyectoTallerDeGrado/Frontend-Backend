"use client";

import { animate, createSeededRandom, createTimeline, onScroll, stagger, utils } from "animejs";
import { Bot, GraduationCap, Route, Trophy, UserCheck, Users, type LucideIcon } from "lucide-react";

import { PROBLEMS, type ProblemIcon } from "../content";
import { useAnimeScope } from "../hooks/use-anime-scope";

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
 * «El problema» y «El giro», en una sola escena fijada (escritorio, con movimiento):
 * 1) caen las notas con lo que frena a quien emprende y la idea se apaga;
 * 2) el fondo pasa de tinta a azul y la idea se reenciende;
 * 3) cada nota se voltea y muestra lo que el CIE-U pone para resolverlo.
 * En móvil, sin movimiento o sin JS se ve la lista de pares problema → respuesta.
 */
export function ProblemSolution() {
  const ref = useAnimeScope<HTMLElement>((_reduced, root) => {
    // La escena fijada debe estar visible antes de que onScroll mida su tamaño.
    root.setAttribute("data-anim", "on");

    // Lista (móvil): cada par se revela al entrar.
    utils.set(".pair", { opacity: 0, y: 24 });
    animate(".pair", {
      opacity: 1,
      y: 0,
      duration: 700,
      delay: stagger(110),
      ease: "out(4)",
      autoplay: onScroll({ target: root.querySelector<HTMLElement>(".ps-list")!, enter: "end start+=80", repeat: false }),
    });
    utils.set(".pair-answer", { opacity: 0, x: -16 });
    animate(".pair-answer", {
      opacity: 1,
      x: 0,
      duration: 600,
      delay: stagger(110, { start: 450 }),
      ease: "out(3)",
      autoplay: onScroll({ target: root.querySelector<HTMLElement>(".ps-list")!, enter: "end start+=80", repeat: false }),
    });

    // Escena fijada (escritorio).
    const notes = root.querySelectorAll<HTMLElement>(".note");
    notes.forEach((note, i) => {
      utils.set(note, { y: "-110vh", x: TILT[i].drift, rotate: TILT[i].rotate * 3, opacity: 0 });
    });
    utils.set(".note-inner", { rotateY: 0 });
    utils.set(".ps-title-b", { opacity: 0, y: 40 });
    utils.set(".ps-sub-b", { opacity: 0 });

    const ink = css(root, "--foreground");
    const blue = css(root, "--primary");
    utils.set(".ps-bg", { backgroundColor: ink });

    const tl = createTimeline({
      defaults: { ease: "linear" },
      autoplay: onScroll({ target: root.querySelector<HTMLElement>(".ps-pinned")!, enter: "start start", leave: "end end", sync: 0.5 }),
    });

    // 1) Caen las notas (0–380) y la idea se apaga y tiembla.
    notes.forEach((note, i) => {
      tl.add(note, { y: 0, x: 0, rotate: TILT[i].rotate, opacity: 1, duration: 170, ease: "outBounce" }, 30 + i * 55);
    });
    tl.add(".bulb-glow", { scale: [1, 0.35], opacity: [1, 0.15], duration: 360 }, 0)
      .add(".bulb", { scale: [1, 0.8], duration: 360 }, 0)
      .add(".bulb", { x: [0, -6, 6, -4, 4, 0], duration: 80 }, 360)
      .add(".bulb-label", { opacity: [1, 0.4], duration: 300 }, 0);

    // 2) El giro: cambia el fondo, el título y la idea se reenciende (450–560).
    tl.add(".ps-bg", { backgroundColor: blue, duration: 110 }, 460)
      .add(".ps-title-a", { opacity: 0, y: -40, duration: 70 }, 450)
      .add(".ps-sub-a", { opacity: 0, duration: 60 }, 450)
      .add(".ps-title-b", { opacity: 1, y: 0, duration: 90, ease: "out(3)" }, 500)
      .add(".ps-sub-b", { opacity: 1, duration: 80 }, 530)
      .add(".bulb", { scale: 1.15, duration: 110, ease: "outBack(3)" }, 480)
      .add(".bulb-glow", { scale: 1.6, opacity: 1, duration: 140, ease: "out(3)" }, 480)
      .add(".bulb-label", { opacity: 1, duration: 60 }, 500)
      .add(".bulb-ring", { scale: [0.6, 2.4], opacity: [0.8, 0], duration: 160, ease: "out(2)" }, 490);

    // 3) Las notas se voltean y se enderezan (580–960).
    notes.forEach((note, i) => {
      tl.add(note.querySelector(".note-inner")!, { rotateY: 180, duration: 120, ease: "inOut(3)" }, 590 + i * 60).add(
        note,
        { rotate: 0, duration: 120, ease: "out(3)" },
        590 + i * 60,
      );
    });
    tl.add(".ps-cta", { opacity: [0, 1], y: [20, 0], duration: 60 }, 940);
  });

  return (
    <section ref={ref} data-anim="pending" id="problema" aria-labelledby="problema-title" className="ps relative scroll-mt-16">
      {/* Lista legible: móvil, movimiento reducido o sin JavaScript. */}
      <div className="ps-list bg-foreground px-5 py-24 text-white sm:px-8">
        <div className="mx-auto max-w-[1240px]">
          <h2 id="problema-title" className="max-w-[18ch] font-heading text-[clamp(34px,5vw,60px)] leading-[1.02] font-bold tracking-[-.03em] text-balance">
            Casi ninguna idea muere por mala. Muere por quedarse sola.
          </h2>
          <p className="mt-5 max-w-[52ch] text-lg leading-relaxed text-on-navy-muted">
            Esto es lo que frena a la mayoría. Y esto es lo que el CIE-U pone para que no te pase.
          </p>
          <ul className="mt-12 grid gap-4 md:grid-cols-2">
            {PROBLEMS.map((p) => {
              const Icon = ICONS[p.icon];
              return (
                <li key={p.problem} className="pair rounded-3xl bg-white/[.06] p-5 ring-1 ring-white/10">
                  <p className="text-[17px] text-on-navy-muted line-through decoration-accent-bright decoration-2">«{p.problem}»</p>
                  <p className="pair-answer mt-3 flex items-start gap-3 text-lg font-semibold">
                    <span className="flex size-9 shrink-0 items-center justify-center rounded-xl bg-primary">
                      <Icon aria-hidden="true" className="size-5" />
                    </span>
                    {p.answer}
                  </p>
                </li>
              );
            })}
          </ul>
        </div>
      </div>

      {/* Escena fijada (solo escritorio con movimiento). */}
      <div aria-hidden="true" className="ps-pinned hidden h-[330vh]">
        <div className="ps-bg sticky top-0 h-screen overflow-hidden text-white">
          <div className="mx-auto grid h-full max-w-[1240px] grid-cols-[0.9fr_1.1fr] items-center gap-10 px-8">
            <div className="relative">
              <div className="relative min-h-[260px]">
                <p className="ps-title-a absolute inset-x-0 top-0 font-heading text-[clamp(40px,4.6vw,64px)] leading-[1.02] font-bold tracking-[-.03em]">
                  Casi ninguna idea muere por mala. Muere por quedarse sola.
                </p>
                <p className="ps-title-b absolute inset-x-0 top-0 font-heading text-[clamp(44px,5.4vw,76px)] leading-[1] font-bold tracking-[-.035em]">
                  Por eso existe el <span className="whitespace-nowrap">CIE-U.</span>
                </p>
              </div>
              <div className="relative mt-6 min-h-[84px] max-w-[42ch] text-lg leading-relaxed">
                <p className="ps-sub-a absolute inset-0 text-on-navy-muted">
                  Sigue bajando: estas son las frases que más se escuchan cuando un proyecto se queda a medias.
                </p>
                <p className="ps-sub-b absolute inset-0 text-white/90">
                  Cada problema tiene una respuesta concreta dentro del programa. Gratis para estudiantes de la UAGRM.
                </p>
              </div>
              <a
                href="/apply"
                tabIndex={-1}
                className="ps-cta mt-8 inline-flex min-h-14 items-center rounded-2xl bg-white px-7 text-base font-bold text-primary opacity-0"
              >
                Quiero esto para mi idea
              </a>
            </div>

            <div className="relative">
              {/* La idea: se apaga cuando caen las notas y se reenciende con el giro. */}
              <div className="bulb absolute top-1/2 left-1/2 -z-0 flex size-40 -translate-x-1/2 -translate-y-1/2 items-center justify-center">
                <span className="bulb-glow absolute -inset-24 rounded-full bg-accent-bright/40 blur-3xl" />
                <span className="bulb-ring absolute inset-0 rounded-full border-4 border-white opacity-0" />
                <span className="relative flex size-full items-center justify-center rounded-full bg-accent-bright text-on-accent shadow-[0_0_80px_var(--accent-bright)]">
                  <span className="bulb-label font-heading text-xl font-bold">tu idea</span>
                </span>
              </div>

              <ul className="relative z-10 grid grid-cols-2 gap-4 [perspective:1200px]">
                {PROBLEMS.map((p, i) => {
                  const Icon = ICONS[p.icon];
                  return (
                    <li key={p.problem} className={`note h-[132px] ${i % 2 ? "translate-y-6" : ""}`}>
                      <div className="note-inner relative size-full [transform-style:preserve-3d]">
                        <div className="absolute inset-0 flex items-center rounded-2xl bg-warning-soft p-5 text-[17px] leading-snug font-semibold text-warning-foreground shadow-[0_20px_40px_-20px_rgb(0_0_0/.7)] [backface-visibility:hidden]">
                          «{p.problem}»
                        </div>
                        <div className="absolute inset-0 flex [transform:rotateY(180deg)] flex-col justify-center gap-2.5 rounded-2xl bg-white p-5 text-navy-950 shadow-[0_24px_50px_-20px_rgb(2_31_80/.8)] [backface-visibility:hidden]">
                          <span className="flex size-9 items-center justify-center rounded-xl bg-primary text-white">
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
          </div>
        </div>
      </div>
    </section>
  );
}
