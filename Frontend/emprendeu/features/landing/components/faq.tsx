"use client";

import { animate } from "animejs";
import { Plus } from "lucide-react";
import { useId, useRef, useState } from "react";

import { cn } from "@/lib/utils";

import { FAQ } from "../content";

const reduced = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function Item({ q, a }: { q: string; a: string }) {
  const [open, setOpen] = useState(false);
  const panel = useRef<HTMLDivElement>(null);
  const id = useId();

  const toggle = () => {
    const el = panel.current!;
    if (reduced()) {
      setOpen(!open);
      return;
    }
    if (!open) {
      el.style.height = "0px";
      setOpen(true);
      requestAnimationFrame(() =>
        animate(el, {
          height: [0, el.scrollHeight],
          opacity: [0, 1],
          duration: 420,
          ease: "out(4)",
          onComplete: () => (el.style.height = "auto"),
        }),
      );
    } else {
      animate(el, { height: [el.scrollHeight, 0], opacity: [1, 0], duration: 260, ease: "in(2)", onComplete: () => setOpen(false) });
    }
  };

  return (
    <li className="border-b border-border">
      <h3>
        <button
          type="button"
          aria-expanded={open}
          aria-controls={id}
          onClick={toggle}
          className="group flex min-h-16 w-full items-center justify-between gap-6 py-5 text-left font-heading text-[clamp(18px,1.8vw,22px)] font-semibold outline-none focus-visible:ring-3 focus-visible:ring-primary/30"
        >
          {q}
          <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-blue-50 text-primary transition-colors group-hover:bg-primary group-hover:text-white">
            <Plus
              aria-hidden="true"
              className={cn("size-5 transition-transform duration-300 ease-[cubic-bezier(.3,1.4,.5,1)]", open && "rotate-[135deg]")}
            />
          </span>
        </button>
      </h3>
      <div ref={panel} id={id} role="region" aria-label={q} hidden={!open} className="overflow-hidden">
        <p className="max-w-[60ch] pb-6 text-[17px] leading-relaxed text-muted-foreground">{a}</p>
      </div>
    </li>
  );
}

/** Preguntas frecuentes (acordeón: el movimiento responde a la persona). */
export function Faq() {
  return (
    <section aria-labelledby="faq-title" className="bg-background pb-24 sm:pb-32">
      <div className="mx-auto grid max-w-[1240px] gap-10 px-5 sm:px-8 lg:grid-cols-[0.8fr_1.2fr]">
        <h2 id="faq-title" className="font-heading text-[clamp(32px,4vw,52px)] leading-[1.02] font-bold tracking-[-.03em]">
          Lo que más nos preguntan.
        </h2>
        <ul className="border-t border-border">
          {FAQ.map((f) => (
            <Item key={f.q} q={f.q} a={f.a} />
          ))}
        </ul>
      </div>
    </section>
  );
}
