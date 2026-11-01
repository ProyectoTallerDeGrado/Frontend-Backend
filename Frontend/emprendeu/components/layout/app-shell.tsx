import Image from "next/image";
import type { ReactNode } from "react";
import { LogOut } from "lucide-react";

import { initials } from "@/lib/format";

import { SidebarNav, type NavItem } from "./sidebar-nav";
import { Toaster } from "./toaster";

type ShellUser = { name: string; roleLabel: string };

type AppShellProps = {
  user: ShellUser;
  nav: NavItem[];
  logoutAction: () => Promise<void>;
  children: ReactNode;
};

/** Estructura del área autenticada: sidebar azul + contenido. Recibe todo por props (sin negocio). */
export function AppShell({ user, nav, logoutAction, children }: AppShellProps) {
  return (
    <div className="flex min-h-screen flex-wrap">
      <aside className="flex w-full shrink-0 flex-col gap-7 bg-navy-950 px-4 py-7 text-white lg:min-h-screen lg:w-[264px]">
        <div className="flex items-center gap-3 px-2">
          <Image
            src="/brand/cie-u-logo.png"
            alt="Logo del CIE-U"
            width={44}
            height={44}
            className="size-11 rounded-[11px] object-cover ring-1 ring-white/20"
          />
          <div>
            <div className="font-heading text-[17px] font-bold tracking-[.01em]">CIE-U</div>
            <div className="text-[13px] text-on-navy-faint">Administración</div>
          </div>
        </div>

        <SidebarNav items={nav} />

        <div className="flex flex-col gap-3 lg:mt-auto">
          <div className="flex items-center gap-3 rounded-[14px] bg-white/[.07] p-3">
            <div
              aria-hidden="true"
              className="flex size-10 shrink-0 items-center justify-center rounded-full bg-primary text-sm font-bold"
            >
              {initials(user.name)}
            </div>
            <div className="min-w-0">
              <div className="truncate text-sm font-semibold">{user.name}</div>
              <div className="truncate text-xs text-on-navy-faint">{user.roleLabel}</div>
            </div>
          </div>
          <form action={logoutAction}>
            <button
              type="submit"
              className="flex min-h-11 w-full items-center gap-2.5 rounded-xl px-3.5 text-sm font-semibold text-on-navy-muted outline-none hover:bg-white/10 focus-visible:ring-3 focus-visible:ring-white/40"
            >
              <LogOut aria-hidden="true" className="size-[18px]" />
              Cerrar sesión
            </button>
          </form>
        </div>
      </aside>

      <main className="min-w-0 flex-[999_1_560px] px-5 py-8 sm:px-10 sm:pb-16">{children}</main>
      <Toaster />
    </div>
  );
}
