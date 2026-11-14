"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useLayoutEffect, useRef, useState } from "react";

import { cn } from "@/lib/utils";

export type TabItem = { href: string; label: string };

/** Pestañas-enlace con un subrayado que se desliza hasta la pestaña activa. */
export function TabNav({ label, tabs }: { label: string; tabs: TabItem[] }) {
  const pathname = usePathname();
  const listRef = useRef<HTMLDivElement>(null);
  const [bar, setBar] = useState<{ left: number; width: number } | null>(null);
  const activeHref = tabs.find((t) => pathname === t.href || pathname.startsWith(`${t.href}/`))?.href;

  useLayoutEffect(() => {
    const list = listRef.current;
    const active = list?.querySelector<HTMLElement>('[aria-current="page"]');
    if (!list || !active) {
      setBar(null);
      return;
    }
    const measure = () => setBar({ left: active.offsetLeft, width: active.offsetWidth });
    measure();
    window.addEventListener("resize", measure);
    return () => window.removeEventListener("resize", measure);
  }, [activeHref]);

  return (
    <nav aria-label={label} className="relative -mx-1 overflow-x-auto">
      <div ref={listRef} className="relative flex min-w-max gap-1 border-b border-border px-1">
        {tabs.map((tab) => {
          const active = tab.href === activeHref;
          return (
            <Link
              key={tab.href}
              href={tab.href}
              scroll={false}
              aria-current={active ? "page" : undefined}
              className={cn(
                "inline-flex min-h-12 items-center rounded-t-lg px-4 text-[15px] font-semibold outline-none transition-colors focus-visible:ring-3 focus-visible:ring-primary/30",
                active ? "text-foreground" : "text-muted-foreground hover:text-foreground",
              )}
            >
              {tab.label}
            </Link>
          );
        })}
        {bar && (
          <span
            aria-hidden="true"
            className="absolute bottom-[-1px] left-0 h-[3px] rounded-full bg-primary transition-[transform,width] duration-300 ease-[cubic-bezier(.2,.8,.2,1)]"
            style={{ width: bar.width, transform: `translateX(${bar.left}px)` }}
          />
        )}
      </div>
    </nav>
  );
}
