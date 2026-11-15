import { create } from "zustand";

/**
 * «Pausar animaciones» (WCAG 2.2.2): detiene lo que se mueve solo —órbitas, la palabra del titular,
 * el recorrido del teléfono en móvil—. Lo que sigue al scroll lo controla la persona y no se pausa.
 */
type MotionState = {
  paused: boolean;
  setPaused: (paused: boolean) => void;
};

export const useMotionStore = create<MotionState>((set) => ({
  paused: false,
  setPaused: (paused) => set({ paused }),
}));

export const motionPaused = () => useMotionStore.getState().paused;

type Pausable = { pause: () => unknown; resume: () => unknown };

/** Registra bucles ambientales de anime.js para que sigan el interruptor. Devuelve la función de limpieza. */
export function ambient(items: Pausable[]) {
  const apply = (paused: boolean) => items.forEach((a) => (paused ? a.pause() : a.resume()));
  if (motionPaused()) apply(true);
  return useMotionStore.subscribe((state, prev) => {
    if (state.paused !== prev.paused) apply(state.paused);
  });
}
