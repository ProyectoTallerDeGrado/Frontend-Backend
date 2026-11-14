"use client";

import { useState, type ReactNode } from "react";
import { Menu, X } from "lucide-react";

import { Sheet, SheetClose, SheetContent, SheetTitle, SheetTrigger } from "@/components/ui/sheet";

import { SidebarNav, type NavGroup } from "./sidebar-nav";

/** Barra superior para pantallas < lg: el menú abre como hoja izquierda y se cierra al navegar. */
export function MobileNav({ groups, brand, footer }: { groups: NavGroup[]; brand: ReactNode; footer: ReactNode }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="sticky top-0 z-40 flex h-16 items-center justify-between gap-3 bg-navy-950 px-4 text-white lg:hidden">
      {brand}
      <Sheet open={open} onOpenChange={setOpen}>
        <SheetTrigger
          aria-label="Abrir menú"
          className="flex size-11 items-center justify-center rounded-xl bg-white/[.08] outline-none hover:bg-white/15 focus-visible:ring-3 focus-visible:ring-white/40"
        >
          <Menu aria-hidden="true" className="size-5" />
        </SheetTrigger>
        <SheetContent
          side="left"
          showCloseButton={false}
          className="w-[86vw] max-w-[320px] gap-0 overflow-y-auto border-0 bg-navy-950 p-0 text-white sm:max-w-[320px]"
        >
          <div className="flex items-center justify-between px-5 pt-5 pb-4">
            <SheetTitle className="sr-only">Menú</SheetTitle>
            {brand}
            <SheetClose
              aria-label="Cerrar menú"
              className="flex size-11 items-center justify-center rounded-xl bg-white/[.08] outline-none hover:bg-white/15 focus-visible:ring-3 focus-visible:ring-white/40"
            >
              <X aria-hidden="true" className="size-5" />
            </SheetClose>
          </div>
          <div className="flex flex-1 flex-col gap-6 px-4 pb-6">
            <SidebarNav groups={groups} onNavigate={() => setOpen(false)} />
            <div className="mt-auto" onClick={() => setOpen(false)}>
              {footer}
            </div>
          </div>
        </SheetContent>
      </Sheet>
    </div>
  );
}
