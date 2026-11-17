"use client";

import { useCallback, useEffect, useLayoutEffect, useRef, useState } from "react";
import { X } from "lucide-react";

import { cn } from "@/lib/utils";

import { completeTutorialAction } from "../../server/actions";
import { useTourStore } from "../../stores/tour-store";
import type { TourStep } from "./tour-steps";

const GAP = 14;
const MARGIN = 16;
const PAD = 6;

type Box = { top: number; left: number; width: number; height: number };

/** Primer elemento visible con `data-tour` (el menú existe dos veces: escritorio y hoja móvil). */
function findTarget(id: string): HTMLElement | null {
  const nodes = document.querySelectorAll<HTMLElement>(`[data-tour="${id}"]`);
  for (const node of nodes) {
    const r = node.getBoundingClientRect();
    if (r.width > 0 && r.height > 0) return node;
  }
  return null;
}

/** Ubica el globo junto al recorte: a la derecha, debajo, arriba o a la izquierda, sin salirse. */
function placeCard(spot: Box, card: { width: number; height: number }) {
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  const clampTop = (t: number) => Math.min(Math.max(t, MARGIN), vh - card.height - MARGIN);
  const clampLeft = (l: number) => Math.min(Math.max(l, MARGIN), vw - card.width - MARGIN);
  if (spot.left + spot.width + GAP + card.width + MARGIN <= vw)
    return { top: clampTop(spot.top), left: spot.left + spot.width + GAP };
  if (spot.top + spot.height + GAP + card.height + MARGIN <= vh)
    return { top: spot.top + spot.height + GAP, left: clampLeft(spot.left + spot.width - card.width) };
  if (spot.top - GAP - card.height >= MARGIN)
    return { top: spot.top - GAP - card.height, left: clampLeft(spot.left + spot.width - card.width) };
  return { top: clampTop(spot.top), left: clampLeft(spot.left - GAP - card.width) };
}

/**
 * Tutorial guiado: oscurece la pantalla, recorta el elemento del paso y explica qué hace.
 * Con `autoStart` (primer ingreso) arranca solo; al terminar o saltarlo se marca en el backend.
 */
export function GuidedTour({ steps, autoStart }: { steps: TourStep[]; autoStart: boolean }) {
  const { open, step, start, close, go } = useTourStore();
  // Recorte medido para un paso concreto: si el paso no tiene elemento visible, no hay recorte.
  const [measured, setMeasured] = useState<{ id: string; box: Box } | null>(null);
  const [cardSize, setCardSize] = useState({ width: 360, height: 240 });
  const cardRef = useRef<HTMLDivElement>(null);
  const nextRef = useRef<HTMLButtonElement>(null);
  const current = steps[Math.min(step, steps.length - 1)];
  const last = step >= steps.length - 1;
  const spot = measured && measured.id === current?.id ? measured.box : null;

  useEffect(() => {
    if (!autoStart) return;
    const timer = window.setTimeout(start, 700);
    return () => window.clearTimeout(timer);
  }, [autoStart, start]);

  const finish = useCallback(() => {
    close();
    void completeTutorialAction();
  }, [close]);

  // Medir el elemento del paso y seguirlo al hacer scroll o cambiar el tamaño de la ventana.
  useLayoutEffect(() => {
    if (!open || !current) return;
    const el = current.target ? findTarget(current.target) : null;
    if (!el) return;
    el.scrollIntoView({ block: "nearest" });
    let frame = 0;
    const measure = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        const r = el.getBoundingClientRect();
        setMeasured({
          id: current.id,
          box: { top: r.top - PAD, left: r.left - PAD, width: r.width + PAD * 2, height: r.height + PAD * 2 },
        });
      });
    };
    measure();
    window.addEventListener("resize", measure);
    window.addEventListener("scroll", measure, true);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("resize", measure);
      window.removeEventListener("scroll", measure, true);
    };
  }, [open, current]);

  useLayoutEffect(() => {
    const card = cardRef.current;
    if (!open || !card) return;
    const { width, height } = card.getBoundingClientRect();
    setCardSize((s) => (s.width === width && s.height === height ? s : { width, height }));
    nextRef.current?.focus();
  }, [open, step, spot]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") finish();
      else if (e.key === "ArrowRight" && !last) go(step + 1);
      else if (e.key === "ArrowLeft" && step > 0) go(step - 1);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, step, last, go, finish]);

  if (!open || !current) return null;

  const position = spot ? placeCard(spot, cardSize) : null;

  return (
    <div className="fixed inset-0 z-[60]">
      {/* Bloquea los clics a la página mientras dura el tutorial. */}
      <div className={cn("absolute inset-0", !spot && "bg-navy-950/60")} aria-hidden="true" />
      {spot && (
        <div
          aria-hidden="true"
          className="tour-spot pointer-events-none absolute rounded-2xl shadow-[0_0_0_9999px_color-mix(in_oklab,var(--color-navy-950)_62%,transparent)] ring-2 ring-accent-bright"
          style={spot}
        />
      )}
      <div
        key={current.id}
        ref={cardRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="tour-title"
        aria-describedby="tour-body"
        className={cn(
          "tour-pop absolute w-[min(360px,calc(100vw-2rem))] rounded-2xl bg-card p-5 text-card-foreground shadow-overlay",
          !position && "top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2",
        )}
        style={position ?? undefined}
      >
        <div className="flex items-start justify-between gap-3">
          <p className="text-xs font-semibold text-muted-foreground">
            Paso {step + 1} de {steps.length}
          </p>
          <button
            type="button"
            onClick={finish}
            aria-label="Saltar el tutorial"
            className="-mt-1.5 -mr-1.5 flex size-8 items-center justify-center rounded-lg text-muted-foreground outline-none hover:bg-muted hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/40"
          >
            <X aria-hidden="true" className="size-4" />
          </button>
        </div>
        <h2 id="tour-title" className="mt-1 font-heading text-lg leading-snug font-bold">
          {current.title}
        </h2>
        <div id="tour-body" className="mt-2 text-sm leading-relaxed text-ink-2">
          <p>{current.body}</p>
          {current.items && (
            <ul className="mt-2.5 flex flex-col gap-1.5">
              {current.items.map((item) => (
                <li key={item.label}>
                  <strong className="text-foreground">{item.label}</strong>
                  {item.text && <>: {item.text}</>}
                </li>
              ))}
            </ul>
          )}
        </div>
        <div className="mt-4 flex items-center gap-1.5" aria-hidden="true">
          {steps.map((s, i) => (
            <span
              key={s.id}
              className={cn("h-1.5 rounded-full transition-all duration-300", i === step ? "w-5 bg-primary" : "w-1.5 bg-border-strong")}
            />
          ))}
        </div>
        <div className="mt-4 flex items-center justify-between gap-2">
          {step === 0 ? (
            <button
              type="button"
              onClick={finish}
              className="min-h-10 rounded-xl px-3 text-sm font-semibold text-muted-foreground outline-none hover:bg-muted hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/40"
            >
              Saltar tutorial
            </button>
          ) : (
            <button
              type="button"
              onClick={() => go(step - 1)}
              className="min-h-10 rounded-xl px-3 text-sm font-semibold text-muted-foreground outline-none hover:bg-muted hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/40"
            >
              Anterior
            </button>
          )}
          <button
            ref={nextRef}
            type="button"
            onClick={() => (last ? finish() : go(step + 1))}
            className="min-h-10 rounded-xl bg-primary px-4 text-sm font-semibold text-primary-foreground outline-none transition-colors hover:bg-primary-hover focus-visible:ring-3 focus-visible:ring-ring/40"
          >
            {last ? "Empezar" : step === 0 ? "Comenzar recorrido" : "Siguiente"}
          </button>
        </div>
      </div>
    </div>
  );
}
