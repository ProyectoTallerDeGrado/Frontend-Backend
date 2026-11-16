"use client";

import Link from "next/link";
import { Menu, X } from "lucide-react";
import { useEffect, useId, useState } from "react";

import { NAV_LINKS } from "../content";

/**
 * Menú de secciones bajo `lg` (en escritorio los enlaces van en la cabecera). Se cierra al elegir
 * un enlace o con Escape; el enlace del personal también vive aquí porque en móvil no cabe arriba.
 */
export function MobileMenu({ staffHref, staffLabel }: { staffHref: string; staffLabel: string }) {
  const [open, setOpen] = useState(false);
  const panelId = useId();

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  const Icon = open ? X : Menu;
  const linkClass =
    "flex min-h-12 items-center rounded-lg px-3 text-[17px] font-semibold outline-none hover:bg-white/10 focus-visible:ring-3 focus-visible:ring-white/40";

  return (
    <div className="lg:hidden">
      <button
        type="button"
        aria-expanded={open}
        aria-controls={panelId}
        aria-label={open ? "Cerrar menú" : "Abrir menú"}
        onClick={() => setOpen(!open)}
        className="flex size-11 items-center justify-center rounded-lg text-white outline-none hover:bg-white/10 focus-visible:ring-3 focus-visible:ring-white/40"
      >
        <Icon aria-hidden="true" className="size-6" />
      </button>
      <nav
        id={panelId}
        aria-label="Secciones"
        hidden={!open}
        className="absolute inset-x-0 top-full border-t border-white/10 bg-navy-950 px-5 pt-3 pb-5 shadow-float sm:px-8"
      >
        <ul className="flex flex-col">
          {NAV_LINKS.map((l) => (
            <li key={l.href}>
              <a href={l.href} onClick={() => setOpen(false)} className={`${linkClass} text-white`}>
                {l.label}
              </a>
            </li>
          ))}
          <li className="mt-2 border-t border-white/10 pt-2">
            <Link href={staffHref} onClick={() => setOpen(false)} className={`${linkClass} text-on-navy-muted`}>
              {staffLabel}
            </Link>
          </li>
        </ul>
      </nav>
    </div>
  );
}
