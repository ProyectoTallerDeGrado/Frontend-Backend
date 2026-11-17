"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useLayoutEffect, useRef, useState } from "react";
import {
  Award,
  Bell,
  BookOpen,
  CalendarClock,
  CalendarDays,
  ChartColumn,
  ChevronDown,
  ClipboardCheck,
  ClipboardList,
  FileSpreadsheet,
  GraduationCap,
  HeartPulse,
  LayoutDashboard,
  LifeBuoy,
  Rocket,
  ShieldCheck,
  SlidersHorizontal,
  UserCheck,
  UserPlus,
  UserRound,
  Users,
  type LucideIcon,
} from "lucide-react";

import { cn } from "@/lib/utils";

const ICONS = {
  dashboard: LayoutDashboard,
  users: Users,
  roles: ShieldCheck,
  tracking: SlidersHorizontal,
  catalogs: Award,
  audit: ClipboardList,
  account: UserRound,
  knowledge: BookOpen,
  entrepreneurs: UserPlus,
  ventures: Rocket,
  alerts: Bell,
  needs: LifeBuoy,
  admissions: ClipboardCheck,
  dashboard2: ChartColumn,
  reports: FileSpreadsheet,
  assignments: UserCheck,
  availability: CalendarClock,
  sessions: CalendarDays,
  training: GraduationCap,
  health: HeartPulse,
} satisfies Record<string, LucideIcon>;

export type NavItem = { href: string; label: string; icon: keyof typeof ICONS; badge?: number };
/** `tourId`: valor de `data-tour` del grupo, para que el tutorial guiado lo resalte. */
export type NavGroup = { label: string; items: NavItem[]; tourId?: string };

/** ¿`href` es la sección en la que está el usuario? (`/` solo coincide consigo misma). */
export function isActiveHref(pathname: string, href: string): boolean {
  return href === "/" ? pathname === "/" : pathname === href || pathname.startsWith(`${href}/`);
}

/** La sección activa es la de `href` más largo que coincide (así `/mentoring/sessions` gana a `/mentoring`). */
function activeHrefOf(pathname: string, groups: NavGroup[]): string | undefined {
  return groups
    .flatMap((g) => g.items)
    .filter((i) => isActiveHref(pathname, i.href))
    .sort((a, b) => b.href.length - a.href.length)[0]?.href;
}

/**
 * Menú agrupado por tarea. Un indicador se desliza hasta el ítem activo al navegar
 * y cada grupo se puede plegar.
 */
export function SidebarNav({ groups, onNavigate }: { groups: NavGroup[]; onNavigate?: () => void }) {
  const pathname = usePathname();
  const navRef = useRef<HTMLElement>(null);
  const [closed, setClosed] = useState<Record<string, boolean>>({});
  const [marker, setMarker] = useState<{ top: number; height: number } | null>(null);
  const activeHref = activeHrefOf(pathname, groups);

  useLayoutEffect(() => {
    const nav = navRef.current;
    if (!nav) return;
    const measure = () => {
      const active = nav.querySelector<HTMLElement>('a[aria-current="page"]');
      if (!active || active.offsetParent === null) {
        setMarker(null);
        return;
      }
      const navBox = nav.getBoundingClientRect();
      const box = active.getBoundingClientRect();
      setMarker({ top: box.top - navBox.top, height: box.height });
    };
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(nav);
    return () => observer.disconnect();
  }, [activeHref, closed]);

  return (
    <nav ref={navRef} aria-label="Secciones" data-tour="nav" className="relative flex flex-col gap-4">
      {marker && (
        <span
          aria-hidden="true"
          className="pointer-events-none absolute inset-x-0 top-0 rounded-xl bg-white/[.14] transition-[transform,height] duration-300 ease-[cubic-bezier(.2,.8,.2,1)]"
          style={{ transform: `translateY(${marker.top}px)`, height: marker.height }}
        />
      )}
      {groups.map((group) => {
        const hasActive = group.items.some((i) => i.href === activeHref);
        const isClosed = !hasActive && closed[group.label];
        const listId = `nav-${group.label.toLowerCase().replace(/\s+/g, "-")}`;
        const showHeading = groups.length > 1 && group.items.length > 1;
        return (
          <div key={group.label} data-tour={group.tourId} className="flex flex-col gap-0.5">
            {showHeading && (
              <button
                type="button"
                aria-expanded={!isClosed}
                aria-controls={listId}
                onClick={() => setClosed((c) => ({ ...c, [group.label]: !c[group.label] }))}
                className="group/heading flex min-h-9 items-center justify-between rounded-lg px-3.5 text-[12.5px] font-semibold text-on-navy-dim outline-none transition-colors hover:text-white focus-visible:ring-3 focus-visible:ring-white/40"
              >
                {group.label}
                <ChevronDown
                  aria-hidden="true"
                  className={cn("size-4 transition-transform duration-200", isClosed && "-rotate-90")}
                />
              </button>
            )}
            <div
              id={listId}
              className={cn(
                "grid transition-[grid-template-rows,opacity] duration-300 ease-[cubic-bezier(.2,.8,.2,1)]",
                isClosed ? "grid-rows-[0fr] opacity-0" : "grid-rows-[1fr] opacity-100",
              )}
            >
              <ul className="flex min-h-0 flex-col gap-0.5 overflow-hidden" inert={isClosed || undefined}>
                {group.items.map((item) => {
                  const Icon = ICONS[item.icon];
                  const active = item.href === activeHref;
                  return (
                    <li key={item.href}>
                      <Link
                        href={item.href}
                        onClick={onNavigate}
                        aria-current={active ? "page" : undefined}
                        className={cn(
                          "relative flex min-h-11 items-center gap-3 rounded-xl px-3.5 text-[15px] font-semibold outline-none transition-[background,color,transform] duration-200 focus-visible:ring-3 focus-visible:ring-white/40",
                          active
                            ? "text-white"
                            : "text-on-navy-muted hover:translate-x-[3px] hover:bg-white/[.07] hover:text-white",
                          // Sin indicador medido todavía (primer render), el activo pinta su propio fondo.
                          active && !marker && "bg-white/[.14]",
                        )}
                      >
                        <Icon aria-hidden="true" className="size-5 shrink-0" />
                        <span className="flex-1 truncate">{item.label}</span>
                        {item.badge ? (
                          <span
                            aria-label={`${item.badge} abiertas`}
                            className="min-w-6 rounded-full bg-danger-tint px-2 py-0.5 text-center text-[12px] font-bold text-danger-foreground"
                          >
                            {item.badge > 99 ? "99+" : item.badge}
                          </span>
                        ) : null}
                        <span
                          aria-hidden="true"
                          className={cn(
                            "size-1.5 rounded-full bg-accent-bright transition-[opacity,transform] duration-300",
                            active ? "scale-100 opacity-100" : "scale-0 opacity-0",
                          )}
                        />
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </div>
          </div>
        );
      })}
    </nav>
  );
}
