"use client";

import { Pause, Play } from "lucide-react";
import { useEffect } from "react";

import { useMotionStore } from "../stores/motion-store";

const KEY = "landing-motion";

/**
 * Botón fijo «Pausar animaciones» (WCAG 2.2.2). Recuerda la elección en este navegador y marca
 * `<html data-motion="paused">` para que los bucles de CSS también se detengan. Con «reducir
 * movimiento» no se muestra: ya no se mueve nada.
 */
export function MotionToggle() {
  const paused = useMotionStore((s) => s.paused);
  const setPaused = useMotionStore((s) => s.setPaused);

  useEffect(() => {
    try {
      if (window.localStorage.getItem(KEY) === "paused") setPaused(true);
    } catch {
      // Sin almacenamiento (modo privado): se empieza en movimiento.
    }
  }, [setPaused]);

  useEffect(() => {
    const html = document.documentElement;
    if (paused) html.dataset.motion = "paused";
    else delete html.dataset.motion;
    try {
      window.localStorage.setItem(KEY, paused ? "paused" : "on");
    } catch {
      // Ignorado: la preferencia vale solo para esta visita.
    }
    return () => {
      delete html.dataset.motion;
    };
  }, [paused]);

  const Icon = paused ? Play : Pause;
  return (
    <button
      type="button"
      aria-pressed={paused}
      onClick={() => setPaused(!paused)}
      className="fixed bottom-4 left-4 z-40 inline-flex min-h-11 items-center gap-2 rounded-full bg-navy-950/90 px-4 text-sm font-semibold text-white shadow-float ring-1 ring-white/20 backdrop-blur outline-none hover:bg-navy-900 focus-visible:ring-3 focus-visible:ring-white/60 motion-reduce:hidden"
    >
      <Icon aria-hidden="true" className="size-4" />
      {paused ? "Reanudar animaciones" : "Pausar animaciones"}
    </button>
  );
}
