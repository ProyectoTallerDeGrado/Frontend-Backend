"use client";

import { createScope } from "animejs";
import { useEffect, useRef } from "react";

/** Selector de una pieza animable: `data-part` admite varios nombres separados por espacio. */
export const part = (name: string) => `[data-part~="${name}"]`;

/**
 * Monta las animaciones de anime.js dentro de un `Scope` con raíz en `ref`: los selectores
 * se resuelven solo dentro de esa sección y todo se revierte al desmontar.
 *
 * `setup(reduced, root)` debe poner los estados iniciales con `utils.set` antes de animar.
 * Al terminar, la raíz pasa a `data-anim="on"` (o `"off"` con «reducir movimiento», donde no se
 * anima nada): el CSS solo oculta `[data-reveal]` mientras vale `"pending"`, así no parpadea.
 *
 * Con `lazy` (por defecto) la sección se prepara cuando está a media pantalla de entrar, así no se
 * registran animaciones ni `onScroll` de lo que nadie ve todavía. Una sección que cambia la altura
 * de la página al montarse (la escena fijada) o que está arriba de todo (el hero) pasa `lazy: false`.
 */
export function useAnimeScope<T extends HTMLElement>(
  setup: (reduced: boolean, root: T) => void | (() => void),
  { lazy = true }: { lazy?: boolean } = {},
) {
  const ref = useRef<T>(null);
  const setupRef = useRef(setup);

  useEffect(() => {
    const root = ref.current;
    if (!root) return;
    let scope: ReturnType<typeof createScope> | undefined;

    const mount = () => {
      scope = createScope({
        root,
        mediaQueries: { reduced: "(prefers-reduced-motion: reduce)" },
      }).add((self) => {
        const reduced = Boolean(self?.matches.reduced);
        const cleanup = reduced ? undefined : setupRef.current(false, root);
        root.setAttribute("data-anim", reduced ? "off" : "on");
        return cleanup;
      });
    };

    if (!lazy) {
      mount();
      return () => {
        scope?.revert();
      };
    }

    const io = new IntersectionObserver(
      ([entry]) => {
        if (!entry.isIntersecting) return;
        io.disconnect();
        mount();
      },
      { rootMargin: "50% 0px" },
    );
    io.observe(root);
    return () => {
      io.disconnect();
      scope?.revert();
    };
  }, [lazy]);

  return ref;
}
