"use client";

import { createScope } from "animejs";
import { useEffect, useRef } from "react";

/**
 * Monta las animaciones de anime.js dentro de un `Scope` con raíz en `ref`: los selectores
 * se resuelven solo dentro de esa sección y todo se revierte al desmontar.
 *
 * `setup(reduced, root)` debe poner los estados iniciales con `utils.set` antes de animar.
 * Al terminar, la raíz pasa a `data-anim="on"` (o `"off"` con «reducir movimiento», donde no se
 * anima nada): el CSS solo oculta el contenido mientras vale `"pending"`, así no parpadea.
 */
export function useAnimeScope<T extends HTMLElement>(setup: (reduced: boolean, root: T) => void | (() => void)) {
  const ref = useRef<T>(null);
  const setupRef = useRef(setup);

  useEffect(() => {
    const root = ref.current;
    if (!root) return;
    const scope = createScope({
      root,
      mediaQueries: { reduced: "(prefers-reduced-motion: reduce)" },
    }).add((self) => {
      const reduced = Boolean(self?.matches.reduced);
      const cleanup = reduced ? undefined : setupRef.current(false, root);
      root.setAttribute("data-anim", reduced ? "off" : "on");
      return cleanup;
    });
    return () => {
      scope.revert();
    };
  }, []);

  return ref;
}
