"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Award,
  Bell,
  LifeBuoy,
  BookOpen,
  CalendarClock,
  ClipboardCheck,
  ChartColumn,
  FileSpreadsheet,
  CalendarDays,
  ClipboardList,
  LayoutDashboard,
  Rocket,
  ShieldCheck,
  SlidersHorizontal,
  UserCheck,
  UserPlus,
  UserRound,
  Users,
  type LucideIcon,
} from "lucide-react";

export type NavItem = { href: string; label: string; icon: keyof typeof ICONS; badge?: number };

const ICONS: Record<string, LucideIcon> = {
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
};

export function SidebarNav({ items }: { items: NavItem[] }) {
  const pathname = usePathname();
  return (
    <nav aria-label="Secciones" className="flex flex-col gap-1">
      {items.map((item) => {
        const Icon = ICONS[item.icon];
        const active =
          item.href === "/" ? pathname === "/" : pathname === item.href || pathname.startsWith(`${item.href}/`);
        return (
          <Link
            key={item.href}
            href={item.href}
            aria-current={active ? "page" : undefined}
            className={`flex min-h-[46px] items-center gap-3 rounded-xl px-3.5 text-[15px] font-semibold transition-[background,color,transform] duration-200 outline-none hover:translate-x-[3px] hover:bg-white/10 focus-visible:ring-3 focus-visible:ring-white/40 ${active ? "bg-white/[.14] text-white" : "text-on-navy-muted"}`}
          >
            <Icon aria-hidden="true" className="size-5" />
            <span className="flex-1">{item.label}</span>
            {item.badge ? (
              <span
                aria-label={`${item.badge} abiertas`}
                className="min-w-6 rounded-full bg-[#ffe3e8] px-2 py-0.5 text-center text-[12px] font-bold text-[#8f0f25]"
              >
                {item.badge > 99 ? "99+" : item.badge}
              </span>
            ) : null}
            <span
              className={`size-1.5 rounded-full bg-accent-bright ${active ? "opacity-100" : "opacity-0"}`}
            />
          </Link>
        );
      })}
    </nav>
  );
}
