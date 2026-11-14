"use client";

import { Plus, Trash2 } from "lucide-react";

import { inputClass } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { MEMBER_ROLES, type MemberRole } from "../schemas/ventures-schemas";
import { ROLE_LABELS } from "../roles";

export type Option = { id: number; name: string };
export type TeamRow = { entrepreneurId: number | null; role: MemberRole };

/** Filas «emprendedor + rol» del equipo inicial. Un emprendedor no se repite entre filas. */
export function TeamPicker({
  entrepreneurs,
  team,
  onChange,
}: {
  entrepreneurs: Option[];
  team: TeamRow[];
  onChange: (team: TeamRow[]) => void;
}) {
  const set = (index: number, row: Partial<TeamRow>) => onChange(team.map((m, i) => (i === index ? { ...m, ...row } : m)));
  const chosen = new Set(team.map((m) => m.entrepreneurId).filter((id): id is number => id !== null));

  return (
    <fieldset className="flex flex-col gap-3">
      <legend className="mb-1 text-sm font-semibold">Equipo</legend>
      <p className="-mt-1 text-[13px] leading-snug text-muted-foreground">
        Uno o más emprendedores. Cada uno verá el emprendimiento en su app.
      </p>
      {team.map((row, index) => (
        <div key={index} className="flex items-center gap-2">
          <select
            aria-label={`Emprendedor ${index + 1}`}
            value={row.entrepreneurId ?? ""}
            onChange={(e) => set(index, { entrepreneurId: e.target.value ? Number(e.target.value) : null })}
            className={`${inputClass} min-w-0 flex-[1.6]`}
          >
            <option value="">Elige un emprendedor</option>
            {entrepreneurs.map((o) => (
              <option key={o.id} value={o.id} disabled={o.id !== row.entrepreneurId && chosen.has(o.id)}>
                {o.name}
              </option>
            ))}
          </select>
          <select
            aria-label={`Rol del emprendedor ${index + 1}`}
            value={row.role}
            onChange={(e) => set(index, { role: e.target.value as MemberRole })}
            className={`${inputClass} min-w-0 flex-1`}
          >
            {MEMBER_ROLES.map((r) => (
              <option key={r} value={r}>
                {ROLE_LABELS[r]}
              </option>
            ))}
          </select>
          <Button
            type="button"
            variant="ghost"
            disabled={team.length === 1}
            onClick={() => onChange(team.filter((_, i) => i !== index))}
            className="size-11 shrink-0 rounded-xl"
            aria-label={`Quitar al emprendedor ${index + 1}`}
          >
            <Trash2 aria-hidden="true" className="size-4" />
          </Button>
        </div>
      ))}
      <Button
        type="button"
        variant="outline"
        disabled={team.length >= Math.min(20, entrepreneurs.length)}
        onClick={() => onChange([...team, { entrepreneurId: null, role: "miembro" }])}
        className="h-11 gap-1.5 self-start rounded-xl border-border-strong px-3.5 text-sm font-semibold"
      >
        <Plus aria-hidden="true" className="size-4" />
        Agregar emprendedor
      </Button>
    </fieldset>
  );
}
