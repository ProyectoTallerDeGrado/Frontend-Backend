"use client";

import { useEffect, useRef, useState } from "react";

/**
 * Cifra que cuenta desde 0 hasta `value` al montarse (easeOutCubic).
 * El HTML del servidor ya trae el valor final; con `prefers-reduced-motion` no anima.
 */
export function CountUp({ value, duration = 1100, delay = 0 }: { value: number; duration?: number; delay?: number }) {
  const [shown, setShown] = useState(value);
  const frame = useRef(0);

  useEffect(() => {
    if (value === 0 || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    let start = 0;
    const tick = (now: number) => {
      if (!start) start = now;
      const t = Math.min(1, (now - start) / duration);
      setShown(Math.round(value * (1 - Math.pow(1 - t, 3))));
      if (t < 1) frame.current = requestAnimationFrame(tick);
    };
    const timer = window.setTimeout(() => {
      setShown(0);
      frame.current = requestAnimationFrame(tick);
    }, delay);
    return () => {
      window.clearTimeout(timer);
      cancelAnimationFrame(frame.current);
    };
  }, [value, duration, delay]);

  return (
    <span className="tabular-nums">
      <span aria-hidden="true">{shown.toLocaleString("es-BO")}</span>
      <span className="sr-only">{value.toLocaleString("es-BO")}</span>
    </span>
  );
}
