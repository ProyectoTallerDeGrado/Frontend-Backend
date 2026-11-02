"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Award,
  Bell,
  CalendarClock,
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

export type NavItem = { href: string; label: string; icon: keyof typeof ICONS };

const ICONS: Record<string, LucideIcon> = {
  dashboard: LayoutDashboard,
  users: Users,
  roles: ShieldCheck,
  tracking: SlidersHorizontal,
  catalogs: Award,
  audit: ClipboardList,
  account: UserRound,
  entrepreneurs: UserPlus,
  ventures: Rocket,
  alerts: Bell,
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
            <span
              className={`size-1.5 rounded-full bg-accent-bright ${active ? "opacity-100" : "opacity-0"}`}
            />
          </Link>
        );
      })}
    </nav>
  );
}
