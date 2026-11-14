"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";

import { cn } from "@/lib/utils";

const LINKS = [
  { href: "#problema", label: "El problema" },
  { href: "#camino", label: "El camino" },
  { href: "#app", label: "La app" },
  { href: "#postular", label: "Postular" },
];

/** Cabecera fija: transparente sobre el hero, sólida al bajar, con barra de progreso de lectura. */
export function SiteHeader({ signedIn }: { signedIn: boolean }) {
  const [solid, setSolid] = useState(false);
  const bar = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    let frame = 0;
    const update = () => {
      frame = 0;
      const max = document.documentElement.scrollHeight - window.innerHeight;
      setSolid(window.scrollY > 40);
      if (bar.current) bar.current.style.transform = `scaleX(${max > 0 ? window.scrollY / max : 0})`;
    };
    const onScroll = () => {
      if (!frame) frame = requestAnimationFrame(update);
    };
    update();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      window.removeEventListener("scroll", onScroll);
      cancelAnimationFrame(frame);
    };
  }, []);

  return (
    <header
      className={cn(
        "fixed inset-x-0 top-0 z-50 text-white transition-[background-color,box-shadow,backdrop-filter] duration-300",
        solid ? "bg-navy-950/90 shadow-[0_10px_30px_-20px_rgb(0_0_0/.7)] backdrop-blur-md" : "bg-transparent",
      )}
    >
      <div className="mx-auto flex h-[72px] max-w-[1240px] items-center gap-6 px-5 sm:px-8">
        <Link href="/" className="flex items-center gap-3 rounded-xl outline-none focus-visible:ring-3 focus-visible:ring-white/50">
          <Image src="/brand/cie-u-logo.png" alt="" width={40} height={40} className="size-10 rounded-[10px] object-cover ring-1 ring-white/20" />
          <span className="font-heading text-lg font-bold">CIE-U</span>
        </Link>
        <nav aria-label="Secciones" className="ml-4 hidden items-center gap-1 lg:flex">
          {LINKS.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className="rounded-lg px-3 py-2 text-[15px] font-semibold text-on-navy-muted outline-none transition-colors hover:text-white focus-visible:ring-3 focus-visible:ring-white/40"
            >
              {l.label}
            </a>
          ))}
        </nav>
        <div className="ml-auto flex items-center gap-2">
          <Link
            href={signedIn ? "/panel" : "/login"}
            className="inline-flex min-h-11 items-center rounded-xl px-3.5 text-[15px] font-semibold outline-none transition-colors hover:bg-white/10 focus-visible:ring-3 focus-visible:ring-white/40"
          >
            {signedIn ? "Ir al panel" : "Ingresar"}
          </Link>
          <Link
            href="/apply"
            className="inline-flex min-h-11 items-center rounded-xl bg-accent-bright px-4 text-[15px] font-bold text-on-accent outline-none transition-transform hover:-translate-y-0.5 focus-visible:ring-3 focus-visible:ring-white/50"
          >
            Postula
          </Link>
        </div>
      </div>
      <span aria-hidden="true" ref={bar} className="absolute bottom-0 left-0 h-[3px] w-full origin-left scale-x-0 bg-accent-bright" />
    </header>
  );
}
