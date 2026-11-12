"use client";

import { useTransition } from "react";

import { toast } from "@/components/layout/toast-store";
import { ToggleSwitch } from "@/components/ui/toggle-switch";

import { roleLabel, roleMeta } from "../roles";
import { changeUserRoleAction, setUserStatusAction } from "../server/actions";
import type { Role } from "../types";

type StatusProps = { userId: number; name: string; enabled: boolean; locked: boolean };

/** Habilita o deshabilita la cuenta. La propia cuenta del administrador queda bloqueada. */
export function UserStatusSwitch({ userId, name, enabled, locked }: StatusProps) {
  const [pending, startTransition] = useTransition();
  return (
    <div className="flex items-center gap-2.5">
      <ToggleSwitch
        label={`${enabled ? "Deshabilitar" : "Habilitar"} cuenta de ${name}`}
        checked={enabled}
        disabled={locked || pending}
        onCheckedChange={(next) =>
          startTransition(async () => {
            const result = await setUserStatusAction(userId, next ? "habilitada" : "deshabilitada", name);
            if (result.ok) toast.success(result.message);
            else toast.error(result.message);
          })
        }
        className={locked ? "opacity-45" : undefined}
      />
      <span className={`text-sm font-semibold ${enabled ? "text-success-foreground" : "text-[#8f0f25]"}`}>
        {enabled ? "Habilitada" : "Deshabilitada"}
      </span>
    </div>
  );
}

type RoleProps = { userId: number; name: string; role: string | null; roles: Role[]; editable: boolean };

/** Rol del usuario: etiqueta de color, o lista para cambiarlo si hay permiso. */
export function UserRoleControl({ userId, name, role, roles, editable }: RoleProps) {
  const [pending, startTransition] = useTransition();
  const meta = roleMeta(role);

  if (!editable) {
    return (
      <span
        className="inline-block rounded-full px-3 py-[5px] text-[13px] font-bold"
        style={{ background: meta?.bg ?? "#E7ECF6", color: meta?.fg ?? "#2B3552" }}
      >
        {roleLabel(role)}
      </span>
    );
  }
  return (
    <>
      <label htmlFor={`role-${userId}`} className="sr-only">
        Rol de {name}
      </label>
      <select
        id={`role-${userId}`}
        value={role ?? ""}
        disabled={pending}
        onChange={(e) =>
          startTransition(async () => {
            const result = await changeUserRoleAction(userId, e.target.value, name);
            if (result.ok) toast.success(result.message);
            else toast.error(result.message);
          })
        }
        className="h-10 max-w-full cursor-pointer rounded-full border-0 px-3 text-[13px] font-bold outline-none focus-visible:ring-3 focus-visible:ring-primary/40 disabled:opacity-60"
        style={{ background: meta?.bg ?? "#E7ECF6", color: meta?.fg ?? "#2B3552" }}
      >
        {roles.map((r) => (
          <option key={r.rol_id} value={r.nombre} style={{ background: "#fff", color: "#0E1730" }}>
            {roleLabel(r.nombre)}
          </option>
        ))}
      </select>
    </>
  );
}
