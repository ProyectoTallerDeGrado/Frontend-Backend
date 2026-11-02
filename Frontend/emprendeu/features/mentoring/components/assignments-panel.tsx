"use client";

import { useState } from "react";
import { LoaderCircle, UserCheck } from "lucide-react";

import { Button } from "@/components/ui/button";
import { ToggleSwitch } from "@/components/ui/toggle-switch";
import { formatWhen } from "@/lib/format";

import { assignAdvisorAction, endAssignmentAction, setAdvisorEnabledAction } from "../server/actions";
import type { Assignment, Mentor, VentureOption } from "../types";
import { Field, FormError, inputClass, useRunner } from "@/components/forms/form-bits";

type Props = {
  advisors: Mentor[];
  assignments: Assignment[];
  ventures: VentureOption[];
  canEdit: boolean;
};

const card =
  "rounded-2xl border border-border bg-card p-6 transition-shadow hover:shadow-[0_14px_30px_-18px_rgba(10,26,68,.35)]";

function AdvisorRow({ advisor, canEdit }: { advisor: Mentor; canEdit: boolean }) {
  const { pending, run } = useRunner();
  return (
    <li className="flex items-center gap-4 border-t border-[#eef2fa] py-3 first:border-t-0">
      <div className="min-w-0 flex-1">
        <div className="truncate text-[15px] font-semibold">{advisor.nombre}</div>
        <div className="truncate text-[13px] text-muted-foreground">
          {advisor.especialidad ?? "Sin especialidad registrada"}
        </div>
      </div>
      <span
        className={`rounded-full px-3 py-1 text-[13px] font-bold ${advisor.habilitado ? "bg-success-tint text-success-foreground" : "bg-muted text-muted-foreground"}`}
      >
        {advisor.habilitado ? "Habilitado" : "No habilitado"}
      </span>
      <ToggleSwitch
        label={`${advisor.habilitado ? "Inhabilitar" : "Habilitar"} a ${advisor.nombre}`}
        checked={advisor.habilitado}
        disabled={!canEdit || pending}
        onCheckedChange={(next) => run(() => setAdvisorEnabledAction(advisor.usuario_id, next, advisor.nombre))}
      />
    </li>
  );
}

function AssignForm({ advisors, ventures }: { advisors: Mentor[]; ventures: VentureOption[] }) {
  const enabled = advisors.filter((a) => a.habilitado);
  const [mentorId, setMentorId] = useState("");
  const [ventureId, setVentureId] = useState("");
  const { pending, error, run } = useRunner(() => {
    setMentorId("");
    setVentureId("");
  });

  return (
    <form
      noValidate
      className="flex flex-col gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        run(() => assignAdvisorAction(Number(mentorId), Number(ventureId)));
      }}
    >
      <Field label="Asesor" hint="Solo aparecen los asesores habilitados.">
        {(id) => (
          <select id={id} value={mentorId} onChange={(e) => setMentorId(e.target.value)} className={inputClass}>
            <option value="">Elige un asesor</option>
            {enabled.map((a) => (
              <option key={a.usuario_id} value={a.usuario_id}>
                {a.nombre}
              </option>
            ))}
          </select>
        )}
      </Field>
      <Field label="Emprendimiento">
        {(id) => (
          <select id={id} value={ventureId} onChange={(e) => setVentureId(e.target.value)} className={inputClass}>
            <option value="">Elige un emprendimiento</option>
            {ventures.map((v) => (
              <option key={v.id} value={v.id}>
                {v.name}
              </option>
            ))}
          </select>
        )}
      </Field>
      <FormError message={error} />
      <Button
        type="submit"
        disabled={pending || !mentorId || !ventureId}
        className="h-12 gap-2 self-start rounded-xl px-6 text-[15px] font-bold"
      >
        {pending ? (
          <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />
        ) : (
          <UserCheck aria-hidden="true" className="size-[18px]" />
        )}
        Asignar asesor
      </Button>
    </form>
  );
}

function AssignmentRow({ assignment, canEdit }: { assignment: Assignment; canEdit: boolean }) {
  const { pending, run } = useRunner();
  const active = assignment.estado === "activa";
  return (
    <li className="flex flex-wrap items-center gap-x-4 gap-y-2 border-t border-[#eef2fa] py-3 first:border-t-0">
      <div className="min-w-0 flex-1">
        <div className="truncate text-[15px] font-semibold">
          {assignment.usuario ?? `Asesor ${assignment.usuario_id}`}
          <span className="font-normal text-muted-foreground"> → </span>
          {assignment.emprendimiento ?? `Emprendimiento ${assignment.emprendimiento_id}`}
        </div>
        <div className="text-[13px] text-muted-foreground">
          {active ? "Desde" : "Finalizó"} {formatWhen(active ? assignment.fecha_inicio : assignment.fecha_fin)}
        </div>
      </div>
      <span
        className={`rounded-full px-3 py-1 text-[13px] font-bold ${active ? "bg-blue-50 text-primary" : "bg-muted text-muted-foreground"}`}
      >
        {active ? "Activa" : "Finalizada"}
      </span>
      {active && canEdit && (
        <Button
          type="button"
          variant="outline"
          disabled={pending}
          onClick={() => run(() => endAssignmentAction(assignment.asignacion_id))}
          className="h-11 rounded-xl border-border-strong px-4 text-sm font-semibold"
        >
          {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
          Finalizar
        </Button>
      )}
    </li>
  );
}

export function AssignmentsPanel({ advisors, assignments, ventures, canEdit }: Props) {
  return (
    <div className="flex flex-wrap items-start gap-6">
      <div className="flex min-w-0 flex-[1_1_520px] flex-col gap-6">
        <section className={card}>
          <h2 className="mb-1 font-heading text-lg font-semibold">Asesores</h2>
          <p className="mb-3 text-sm leading-normal text-muted-foreground">
            Solo un asesor habilitado puede recibir asignaciones y agendas.
          </p>
          {advisors.length === 0 ? (
            <p className="py-4 text-sm text-muted-foreground">Aún no hay usuarios con el rol asesor.</p>
          ) : (
            <ul>
              {advisors.map((a) => (
                <AdvisorRow key={a.usuario_id} advisor={a} canEdit={canEdit} />
              ))}
            </ul>
          )}
        </section>

        <section className={card}>
          <h2 className="mb-3 font-heading text-lg font-semibold">Asignaciones</h2>
          {assignments.length === 0 ? (
            <p className="py-4 text-sm text-muted-foreground">Todavía no hay asignaciones.</p>
          ) : (
            <ul>
              {assignments.map((a) => (
                <AssignmentRow key={a.asignacion_id} assignment={a} canEdit={canEdit} />
              ))}
            </ul>
          )}
        </section>
      </div>

      <aside className={`${card} min-w-[280px] flex-[0_1_380px]`}>
        <h2 className="mb-1 font-heading text-lg font-semibold">Asignar asesor</h2>
        <p className="mb-5 text-sm leading-normal text-muted-foreground">
          Un asesor no se asigna dos veces al mismo emprendimiento mientras la asignación siga activa.
        </p>
        {canEdit ? (
          <AssignForm advisors={advisors} ventures={ventures} />
        ) : (
          <p className="rounded-xl bg-muted px-4 py-3 text-sm text-muted-foreground">
            Tu rol puede consultar las asignaciones, pero no crearlas.
          </p>
        )}
      </aside>
    </div>
  );
}
