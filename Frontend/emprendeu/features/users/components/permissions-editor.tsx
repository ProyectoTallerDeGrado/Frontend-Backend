"use client";

import { useState, useTransition } from "react";
import { LoaderCircle, Trash2 } from "lucide-react";

import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";

import { PERMISSION_ACTIONS, PERMISSION_MODULES, SYSTEM_ROLES, roleLabel } from "../roles";
import { deleteRoleAction, savePermissionsAction } from "../server/actions";
import type { PermissionMatrix, Role } from "../types";
import { NewRoleDrawer } from "./new-role-drawer";

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
  const roleName = roleLabel(role.nombre);
  const isCustom = !SYSTEM_ROLES.includes(role.nombre);
  const dirty = normalize(draft) !== normalize(saved[selected] ?? {});

  const toggle = (module: string, action: string) => {
    if (!canEdit) return;
    setDrafts((prev) => {
      const current = prev[selected]?.[module] ?? [];
      const next = current.includes(action) ? current.filter((a) => a !== action) : [...current, action];
      return { ...prev, [selected]: { ...prev[selected], [module]: next } };
    });
  };

  const remove = () => {
    if (!window.confirm(`¿Eliminar el rol ${roleName}? Esta acción no se puede deshacer.`)) return;
    startTransition(async () => {
      const result = await deleteRoleAction(selected, roleName);
      if (result.ok) toast.success(result.message);
      else toast.error(result.message);
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
        {canEdit && <NewRoleDrawer roles={roles} />}
        {roles.map((r) => {
          const on = r.rol_id === selected;
          return (
            <button
              key={r.rol_id}
              type="button"
              aria-pressed={on}
              onClick={() => setSelected(r.rol_id)}
              className={`rounded-2xl border-2 px-[18px] py-4 text-left outline-none focus-visible:ring-3 focus-visible:ring-primary/30 ${on ? "border-primary bg-blue-50" : "border-border bg-card"}`}
            >
              <div className="flex items-center justify-between gap-2">
                <span className="font-heading text-base font-semibold">{roleLabel(r.nombre)}</span>
                <span className="text-[13px] font-bold text-muted-foreground">{r.total_usuarios} {r.total_usuarios === 1 ? "usuario" : "usuarios"}</span>
              </div>
              <div className="mt-1.5 text-[13px] leading-snug text-muted-foreground">{r.descripcion}</div>
            </button>
          );
        })}
      </section>

      <section className="relative min-w-0 flex-[1_1_560px] overflow-hidden rounded-2xl border border-border bg-card">
        <div className="flex items-start justify-between gap-3 border-b border-border px-6 py-5">
          <div>
            <h2 className="font-heading text-lg font-semibold">Permisos · {roleName}</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Se aplican de inmediato a los usuarios con este rol.
            </p>
          </div>
          {canEdit && isCustom && (
            <Button
              type="button"
              variant="outline"
              disabled={pending || role.total_usuarios > 0}
              title={role.total_usuarios > 0 ? "Reasigna a sus usuarios antes de eliminarlo" : undefined}
              onClick={remove}
              className="h-11 gap-2 rounded-xl border-border-strong px-4 text-sm font-semibold"
            >
              <Trash2 aria-hidden="true" className="size-4" />
              Eliminar rol
            </Button>
          )}
        </div>
        <div className="relative overflow-x-auto overflow-y-hidden">
          <table className="w-full min-w-[640px] border-collapse">
            <thead>
              <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
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
                <tr key={m.key} className="border-b border-muted transition-colors hover:bg-row-hover">
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
                        className="size-6 rounded-[7px] border-2 border-switch-off bg-white data-checked:border-primary data-checked:bg-primary after:-inset-2.5 [&_svg]:size-3.5"
                      />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {dirty && (
          <div className="flex animate-[slide-up_.35s_cubic-bezier(.2,.8,.2,1)_both] flex-wrap items-center justify-between gap-3 border-t border-warning-border bg-warning-soft px-6 py-4">
            <span className="text-sm font-semibold text-warning-foreground">Hay cambios sin guardar en {roleName}.</span>
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
