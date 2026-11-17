import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";
import { LogOut } from "lucide-react";

import { initials } from "@/lib/format";

import { MobileNav } from "./mobile-nav";
import { PageTransition } from "./page-transition";
import { SidebarNav, type NavGroup } from "./sidebar-nav";
import { Toaster } from "./toaster";

type ShellUser = { name: string; roleLabel: string };

type AppShellProps = {
  user: ShellUser;
  groups: NavGroup[];
  logoutAction: () => Promise<void>;
  /** Piezas flotantes del área autenticada (chat de ayuda, tutorial guiado) que compone el layout. */
  overlays?: ReactNode;
  children: ReactNode;
};

/** Marca del menú. Debajo va el rol de quien entró (antes decía «Administración» para todos). */
function Brand({ roleLabel }: { roleLabel: string }) {
  return (
    <Link href="/panel" className="flex items-center gap-3 rounded-xl px-1 outline-none focus-visible:ring-3 focus-visible:ring-white/40">
      <Image
        src="/brand/cie-u-logo.png"
        alt=""
        width={44}
        height={44}
        className="size-10 rounded-[11px] object-cover ring-1 ring-white/20 lg:size-11"
      />
      <div>
        <div className="font-heading text-[17px] leading-tight font-bold tracking-[.01em]">CIE-U</div>
        <div className="max-w-[170px] truncate text-[13px] text-on-navy-faint">{roleLabel}</div>
      </div>
    </Link>
  );
}

/** Pie del menú: la tarjeta del usuario lleva a «Mi cuenta»; debajo, cerrar sesión. */
function UserFooter({ user, logoutAction }: { user: ShellUser; logoutAction: () => Promise<void> }) {
  return (
    <div className="flex flex-col gap-1.5 border-t border-white/10 pt-4">
      <Link
        href="/account"
        data-tour="account"
        className="flex items-center gap-3 rounded-[14px] bg-white/[.07] p-3 outline-none transition-colors hover:bg-white/[.12] focus-visible:ring-3 focus-visible:ring-white/40"
      >
        <span
          aria-hidden="true"
          className="flex size-10 shrink-0 items-center justify-center rounded-full bg-primary text-sm font-bold"
        >
          {initials(user.name)}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate text-sm font-semibold">{user.name}</span>
          <span className="block truncate text-xs text-on-navy-faint">{user.roleLabel} · Mi cuenta</span>
        </span>
      </Link>
      <form action={logoutAction}>
        <button
          type="submit"
          className="flex min-h-11 w-full items-center gap-2.5 rounded-xl px-3.5 text-sm font-semibold text-on-navy-muted outline-none transition-colors hover:bg-white/10 hover:text-white focus-visible:ring-3 focus-visible:ring-white/40"
        >
          <LogOut aria-hidden="true" className="size-[18px]" />
          Cerrar sesión
        </button>
      </form>
    </div>
  );
}

/** Estructura del área autenticada: sidebar azul fijo + contenido. Recibe todo por props (sin negocio). */
export function AppShell({ user, groups, logoutAction, overlays, children }: AppShellProps) {
  const footer = <UserFooter user={user} logoutAction={logoutAction} />;
  return (
    <div className="min-h-screen lg:flex">
      <a
        href="#contenido"
        className="sr-only z-50 rounded-xl bg-primary px-4 py-3 font-semibold text-white focus:not-sr-only focus:fixed focus:top-3 focus:left-3"
      >
        Saltar al contenido
      </a>

      <MobileNav groups={groups} brand={<Brand roleLabel={user.roleLabel} />} footer={footer} />

      <aside className="hidden w-[272px] shrink-0 bg-navy-950 text-white lg:sticky lg:top-0 lg:flex lg:h-dvh lg:flex-col">
        <div className="px-5 pt-7 pb-6">
          <Brand roleLabel={user.roleLabel} />
        </div>
        <div className="flex-1 overflow-y-auto px-4 pb-4 [scrollbar-color:rgb(255_255_255/.2)_transparent] [scrollbar-width:thin]">
          <SidebarNav groups={groups} />
        </div>
        <div className="px-4 pb-5">{footer}</div>
      </aside>

      <main id="contenido" tabIndex={-1} className="min-w-0 flex-1 px-4 py-7 outline-none sm:px-8 lg:px-10 lg:pt-9 lg:pb-16">
        <div className="mx-auto max-w-[1280px]">
          <PageTransition>{children}</PageTransition>
        </div>
      </main>
      {overlays}
      <Toaster />
    </div>
  );
}
