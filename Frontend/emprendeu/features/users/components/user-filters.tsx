"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Search } from "lucide-react";

import { Input } from "@/components/ui/input";

import { roleLabel } from "../roles";
import type { Role } from "../types";
import { filterPillClass } from "@/components/data/filter-pills";

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
        <Link href={href(value.trim(), "")} aria-current={rol === "" ? "true" : undefined} className={filterPillClass(rol === "")}>
          Todos
        </Link>
        {roles.map((r) => (
          <Link
            key={r.rol_id}
            href={href(value.trim(), r.nombre)}
            aria-current={rol === r.nombre ? "true" : undefined}
            className={filterPillClass(rol === r.nombre)}
          >
            {roleLabel(r.nombre)}
          </Link>
        ))}
      </div>
    </div>
  );
}
