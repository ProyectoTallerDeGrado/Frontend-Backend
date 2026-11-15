"use client";

import { useState } from "react";
import { LoaderCircle, Trash2, Users } from "lucide-react";

import { Field, FormError, FormSheet, inputClass, useRunner } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { addVentureMemberAction, changeVentureMemberRoleAction, removeVentureMemberAction } from "../server/actions";
import { MEMBER_ROLES, type MemberRole } from "../schemas/ventures-schemas";
import type { Venture, VentureMember } from "../types";
import { ROLE_LABELS } from "../roles";
import type { Option } from "./team-picker";

function fullName(m: VentureMember): string {
  return `${m.nombre ?? ""} ${m.apellido ?? ""}`.trim() || m.email || `Emprendedor ${m.emprendedor_id}`;
}

function TeamManager({ venture, entrepreneurs }: { venture: Venture; entrepreneurs: Option[] }) {
  const members = venture.integrantes;
  const [entrepreneurId, setEntrepreneurId] = useState<number | null>(null);
  const [role, setRole] = useState<MemberRole>("miembro");
  const adding = useRunner(() => setEntrepreneurId(null));
  const removing = useRunner();
  const changing = useRunner();
  const inTeam = new Set(members.map((m) => m.emprendedor_id));
  const available = entrepreneurs.filter((o) => !inTeam.has(o.id));
  const onlyOne = members.length <= 1;

  return (
    <div className="flex min-h-0 flex-1 flex-col gap-6 overflow-y-auto px-7 py-6">
      <section aria-labelledby="team-current" className="flex flex-col gap-3">
        <h3 id="team-current" className="text-sm font-semibold">
          Integrantes ({members.length})
        </h3>
        <ul className="flex flex-col divide-y divide-border rounded-xl border border-border">
          {members.map((m) => (
            <li key={m.emprendedor_id} className="flex items-center gap-3 px-4 py-3">
              <div className="min-w-0 flex-1">
                <p className="truncate font-semibold">{fullName(m)}</p>
                <p className="truncate text-[13px] text-muted-foreground">{m.email ?? ""}</p>
              </div>
              <select
                aria-label={`Rol de ${fullName(m)} en el equipo`}
                value={m.rol_en_emprendimiento ?? "miembro"}
                disabled={changing.pending}
                onChange={(e) =>
                  changing.run(() => changeVentureMemberRoleAction(venture.emprendimiento_id, m.emprendedor_id, e.target.value, fullName(m)))
                }
                className="h-11 rounded-xl border-[1.5px] border-border-strong bg-card px-2 text-sm"
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
                disabled={onlyOne || removing.pending}
                title={onlyOne ? "El emprendimiento debe quedar con al menos un integrante." : undefined}
                onClick={() => removing.run(() => removeVentureMemberAction(venture.emprendimiento_id, m.emprendedor_id, fullName(m)))}
                className="size-11 shrink-0 rounded-xl"
                aria-label={`Quitar a ${fullName(m)} del equipo`}
              >
                <Trash2 aria-hidden="true" className="size-4" />
              </Button>
            </li>
          ))}
        </ul>
        {onlyOne && (
          <p className="text-[13px] text-muted-foreground">Para quitar a este integrante, agrega antes a otro.</p>
        )}
        <FormError message={removing.error ?? changing.error} />
      </section>

      <form
        noValidate
        aria-labelledby="team-add"
        className="flex flex-col gap-4 border-t border-border pt-6"
        onSubmit={(e) => {
          e.preventDefault();
          adding.run(() => addVentureMemberAction(venture.emprendimiento_id, entrepreneurId, role));
        }}
      >
        <h3 id="team-add" className="text-sm font-semibold">
          Agregar integrante
        </h3>
        <Field label="Emprendedor" hint={available.length === 0 ? "Todos los emprendedores registrados ya son parte del equipo." : undefined}>
          {(id) => (
            <select
              id={id}
              value={entrepreneurId ?? ""}
              onChange={(e) => setEntrepreneurId(e.target.value ? Number(e.target.value) : null)}
              className={inputClass}
            >
              <option value="">Elige un emprendedor</option>
              {available.map((o) => (
                <option key={o.id} value={o.id}>
                  {o.name}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label="Rol en el emprendimiento">
          {(id) => (
            <select id={id} value={role} onChange={(e) => setRole(e.target.value as MemberRole)} className={inputClass}>
              {MEMBER_ROLES.map((r) => (
                <option key={r} value={r}>
                  {ROLE_LABELS[r]}
                </option>
              ))}
            </select>
          )}
        </Field>
        <FormError message={adding.error} />
        <Button type="submit" disabled={adding.pending || entrepreneurId === null} className="h-[50px] rounded-xl text-[15px] font-bold">
          {adding.pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
          Agregar al equipo
        </Button>
      </form>
    </div>
  );
}

/** CU05: la coordinación ve, agrega y quita integrantes del emprendimiento. */
export function TeamSheet({ venture, entrepreneurs }: { venture: Venture; entrepreneurs: Option[] }) {
  return (
    <FormSheet
      title={`Equipo · ${venture.nombre}`}
      variant="outline"
      trigger={
        <>
          <Users aria-hidden="true" className="size-4" />
          Equipo
        </>
      }
      triggerClassName="h-11 gap-1.5 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
    >
      {() => <TeamManager venture={venture} entrepreneurs={entrepreneurs} />}
    </FormSheet>
  );
}
