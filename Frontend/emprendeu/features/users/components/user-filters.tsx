"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Search } from "lucide-react";

import { Input } from "@/components/ui/input";

import { roleLabel } from "../roles";
import type { Role } from "../types";

type UserFiltersProps = { q: string; rol: string; roles: Role[] };

function href(q: string, rol: string): string {
  const params = new URLSearchParams();
  if (q) params.set("q", q);
  if (rol) params.set("rol", rol);
  const query = params.toString();
  return query ? `/users?${query}` : "/users";
}

export function UserFilters({ q, rol, roles }: UserFiltersProps) {
  const router = useRouter();
  const pathname = usePathname();
  const [value, setValue] = useState(q);
  const first = useRef(true);

  // Busca al dejar de escribir (350 ms) actualizando la URL.
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    const id = setTimeout(() => router.replace(href(value.trim(), rol)), 350);
    return () => clearTimeout(id);
  }, [value, rol, router, pathname]);

  const pill = (active: boolean) =>
    `inline-flex min-h-11 items-center rounded-full border-[1.5px] px-4 text-sm font-semibold outline-none transition-all focus-visible:ring-3 focus-visible:ring-primary/30 ${active ? "border-navy-900 bg-navy-900 text-white" : "border-border-strong bg-card text-foreground hover:bg-blue-50"}`;

  return (
    <div className="flex flex-wrap items-center gap-3">
      <div className="relative max-w-[420px] min-w-[240px] flex-[1_1_280px]">
        <Search aria-hidden="true" className="absolute top-[15px] left-4 size-[18px] text-muted-foreground" />
        <label htmlFor="user-search" className="sr-only">
          Buscar usuarios
        </label>
        <Input
          id="user-search"
          type="search"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          placeholder="Buscar por nombre o correo"
          className="h-12 rounded-xl border-[1.5px] border-border-strong bg-card pr-4 pl-11 text-[15px] focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15"
        />
      </div>
      <div className="flex flex-wrap gap-2">
        <Link href={href(value.trim(), "")} aria-current={rol === "" ? "true" : undefined} className={pill(rol === "")}>
          Todos
        </Link>
        {roles.map((r) => (
          <Link
            key={r.rol_id}
            href={href(value.trim(), r.nombre)}
            aria-current={rol === r.nombre ? "true" : undefined}
            className={pill(rol === r.nombre)}
          >
            {roleLabel(r.nombre)}
          </Link>
        ))}
      </div>
    </div>
  );
}
