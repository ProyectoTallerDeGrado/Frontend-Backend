"use client";

import { useState, useTransition } from "react";
import { LoaderCircle } from "lucide-react";

import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";

import { PERMISSION_ACTIONS, PERMISSION_MODULES, ROLE_META } from "../roles";
import { savePermissionsAction } from "../server/actions";
import type { PermissionMatrix, Role } from "../types";

type Props = { roles: Role[]; matrices: Record<number, PermissionMatrix>; canEdit: boolean };

const normalize = (m: PermissionMatrix): string =>
  JSON.stringify(PERMISSION_MODULES.map((mod) => [...(m[mod.key] ?? [])].sort()));

export function PermissionsEditor({ roles, matrices, canEdit }: Props) {
  const [selected, setSelected] = useState(roles[0]?.rol_id ?? 0);
  const [drafts, setDrafts] = useState<Record<number, PermissionMatrix>>(matrices);
  const [saved, setSaved] = useState<Record<number, PermissionMatrix>>(matrices);
  const [pending, startTransition] = useTransition();

  const role = roles.find((r) => r.rol_id === selected);
  if (!role) return null;
  const draft = drafts[selected] ?? {};
  const roleName = ROLE_META[role.nombre]?.label ?? role.nombre;
  const dirty = normalize(draft) !== normalize(saved[selected] ?? {});

  const toggle = (module: string, action: string) => {
    if (!canEdit) return;
    setDrafts((prev) => {
      const current = prev[selected]?.[module] ?? [];
      const next = current.includes(action) ? current.filter((a) => a !== action) : [...current, action];
      return { ...prev, [selected]: { ...prev[selected], [module]: next } };
    });
  };

  const save = () =>
    startTransition(async () => {
      const result = await savePermissionsAction(selected, roleName, draft);
      if (result.ok) {
        setSaved((prev) => ({ ...prev, [selected]: draft }));
        toast.success(result.message);
      } else {
        toast.error(result.message);
      }
    });

  return (
    <div className="flex flex-wrap items-start gap-6">
      <section className="flex min-w-[240px] flex-[0_1_300px] flex-col gap-2.5" aria-label="Roles">
        {roles.map((r, i) => {
          const on = r.rol_id === selected;
          return (
            <button
              key={r.rol_id}
              type="button"
              aria-pressed={on}
              onClick={() => setSelected(r.rol_id)}
              style={{ animationDelay: `${i * 60}ms` }}
              className={`animate-[fade-up_.5s_ease_both] rounded-2xl border-2 px-[18px] py-4 text-left outline-none transition-shadow hover:shadow-[0_14px_30px_-18px_rgba(10,26,68,.35)] focus-visible:ring-3 focus-visible:ring-primary/30 ${on ? "border-primary bg-blue-50" : "border-border bg-card"}`}
            >
              <div className="flex items-center justify-between gap-2">
                <span className="font-heading text-base font-semibold">{ROLE_META[r.nombre]?.label ?? r.nombre}</span>
                <span className="text-[13px] font-bold text-muted-foreground">{r.total_usuarios} {r.total_usuarios === 1 ? "usuario" : "usuarios"}</span>
              </div>
              <div className="mt-1.5 text-[13px] leading-snug text-muted-foreground">{r.descripcion}</div>
            </button>
          );
        })}
      </section>

      <section className="relative min-w-0 flex-[1_1_560px] overflow-hidden rounded-2xl border border-border bg-card">
        <div className="border-b border-border px-6 py-5">
          <h2 className="font-heading text-lg font-semibold">Permisos · {roleName}</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Se aplican en el siguiente acceso de los usuarios con este rol.
          </p>
        </div>
        <div className="overflow-x-auto overflow-y-hidden">
          <table className="w-full min-w-[640px] border-collapse">
            <thead>
              <tr className="border-b border-border bg-[#f8fafe] text-[13px] font-bold tracking-[.03em] text-muted-foreground uppercase">
                <th scope="col" className="px-6 py-3 text-left">
                  Módulo
                </th>
                {PERMISSION_ACTIONS.map((a) => (
                  <th key={a.key} scope="col" className="w-[100px] px-1 py-3 text-center">
                    {a.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {PERMISSION_MODULES.map((m) => (
                <tr key={m.key} className="border-b border-[#eef2fa] transition-colors hover:bg-[#f4f7ff]">
                  <th scope="row" className="px-6 py-1 text-left text-[15px] font-semibold">
                    {m.label}
                  </th>
                  {PERMISSION_ACTIONS.map((a) => (
                    <td key={a.key} className="px-1 py-1 text-center">
                      <Checkbox
                        checked={(draft[m.key] ?? []).includes(a.key)}
                        onCheckedChange={() => toggle(m.key, a.key)}
                        disabled={!canEdit}
                        aria-label={`${a.label} en ${m.label}`}
                        className="size-6 rounded-[7px] border-2 border-[#9aa6c4] bg-white data-checked:border-primary data-checked:bg-primary after:-inset-2.5 [&_svg]:size-3.5"
                      />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {dirty && (
          <div className="flex animate-[fade-up_.35s_ease_both] flex-wrap items-center justify-between gap-3 border-t border-[#f0dda0] bg-[#fff6dc] px-6 py-4">
            <span className="text-sm font-semibold text-[#6b4700]">Hay cambios sin guardar en {roleName}.</span>
            <div className="flex gap-2.5">
              <Button
                type="button"
                variant="outline"
                disabled={pending}
                onClick={() => setDrafts((prev) => ({ ...prev, [selected]: saved[selected] ?? {} }))}
                className="h-11 rounded-xl border-border-strong px-[18px] text-sm font-semibold"
              >
                Descartar
              </Button>
              <Button type="button" disabled={pending} onClick={save} className="h-11 gap-2 rounded-xl px-5 text-sm font-bold">
                {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
                {pending ? "Guardando…" : "Guardar cambios"}
              </Button>
            </div>
          </div>
        )}
        {!canEdit && (
          <p className="border-t border-border px-6 py-3 text-[13px] text-muted-foreground">
            Solo lectura: necesitas permiso administrativo sobre usuarios para editar la matriz.
          </p>
        )}
      </section>
    </div>
  );
}
