"use client";

import { useState } from "react";
import { UserCheck } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, inputClass, useRunner } from "@/components/forms/form-bits";

import { assignAdvisorAction } from "../server/actions";
import type { Mentor } from "../types";

type Props = { ventureId: number; ventureName: string; advisors: Mentor[] };

function Form({ ventureId, ventureName, advisors, close }: Props & { close: () => void }) {
  const [mentorId, setMentorId] = useState("");
  const { pending, error, run } = useRunner(close);
  const chosen = advisors.find((a) => String(a.usuario_id) === mentorId);
  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        run(() => assignAdvisorAction(Number(mentorId), ventureId));
      }}
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <p className="text-sm leading-normal text-muted-foreground">
          Asignarás un asesor a <strong className="text-foreground">{ventureName}</strong>. Solo aparecen los asesores
          habilitados; no se repite una asignación activa.
        </p>
        <Field label="Asesor">
          {(id) => (
            <select id={id} value={mentorId} onChange={(e) => setMentorId(e.target.value)} className={inputClass}>
              <option value="">Elige un asesor</option>
              {advisors.map((a) => (
                <option key={a.usuario_id} value={a.usuario_id}>
                  {a.nombre} — {a.especialidad ?? "sin especialidad"}
                </option>
              ))}
            </select>
          )}
        </Field>
        {chosen && (
          <p className="rounded-xl bg-blue-50 px-4 py-3 text-sm text-primary">
            Especialidad: <strong>{chosen.especialidad ?? "No registrada"}</strong>
          </p>
        )}
        {advisors.length === 0 && (
          <p className="rounded-xl bg-muted px-4 py-3 text-sm text-muted-foreground">
            No hay asesores habilitados. Habilítalos en Asignaciones.
          </p>
        )}
        <FormError message={error} />
      </div>
      <SheetFooter pending={pending} label="Confirmar asignación" />
    </form>
  );
}

/** CU09 · Asigna un asesor habilitado al emprendimiento desde la lista de emprendimientos. */
export function AssignAdvisorSheet(props: Props) {
  return (
    <FormSheet
      title="Asignar asesor"
      variant="outline"
      triggerClassName="h-10 gap-2 rounded-xl border-border-strong px-3 text-[13px] font-semibold"
      trigger={
        <>
          <UserCheck aria-hidden="true" className="size-4" />
          Asignar
        </>
      }
    >
      {(close) => <Form {...props} close={close} />}
    </FormSheet>
  );
}
