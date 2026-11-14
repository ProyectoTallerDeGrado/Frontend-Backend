"use client";

import { useState } from "react";
import { Ban, CalendarPlus, LoaderCircle, RotateCcw, Trash2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { boDay, formatDateTime, formatTimeRange } from "@/lib/format";

import { addAvailabilityAction, deleteAvailabilityAction, setAvailabilityStateAction } from "../server/actions";
import type { Availability } from "../types";
import { Field, FormError, inputClass, useRunner } from "@/components/forms/form-bits";

const card =
  "rounded-2xl border border-border bg-card p-6";

const STATE_STYLE: Record<Availability["estado"], { label: string; className: string }> = {
  disponible: { label: "Disponible", className: "bg-success-tint text-success-foreground" },
  bloqueado: { label: "Bloqueado", className: "bg-muted text-muted-foreground" },
  reservado: { label: "Reservado", className: "bg-blue-50 text-primary" },
};

function AddForm({ mentorId }: { mentorId: number }) {
  const [date, setDate] = useState(boDay());
  const [start, setStart] = useState("09:00");
  const [end, setEnd] = useState("11:00");
  const { pending, error, run } = useRunner();

  return (
    <form
      noValidate
      className="flex flex-col gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        run(() => addAvailabilityAction(mentorId, { date, start, end }));
      }}
    >
      <Field label="Día">
        {(id) => (
          <input id={id} type="date" min={boDay()} value={date} onChange={(e) => setDate(e.target.value)} className={inputClass} />
        )}
      </Field>
      <div className="flex gap-3">
        <div className="flex-1">
          <Field label="Desde">
            {(id) => <input id={id} type="time" value={start} onChange={(e) => setStart(e.target.value)} className={inputClass} />}
          </Field>
        </div>
        <div className="flex-1">
          <Field label="Hasta">
            {(id) => <input id={id} type="time" value={end} onChange={(e) => setEnd(e.target.value)} className={inputClass} />}
          </Field>
        </div>
      </div>
      <p className="text-[13px] leading-snug text-muted-foreground">
        Hora de Bolivia. Cada hora completa del intervalo se ofrece como un turno de 60 min.
      </p>
      <FormError message={error} />
      <Button type="submit" disabled={pending} className="h-12 gap-2 self-start rounded-xl px-6 text-[15px] font-bold">
        {pending ? (
          <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />
        ) : (
          <CalendarPlus aria-hidden="true" className="size-[18px]" />
        )}
        Agregar horario
      </Button>
    </form>
  );
}

function Row({ item }: { item: Availability }) {
  const { pending, run } = useRunner();
  const style = STATE_STYLE[item.estado];
  const iconButton =
    "size-11 rounded-xl border-border-strong";
  return (
    <li className="flex flex-wrap items-center gap-x-4 gap-y-2 border-t border-muted py-3 first:border-t-0">
      <div className="min-w-0 flex-1">
        <div className="text-[15px] font-semibold">{formatDateTime(item.fecha_inicio).replace(/, \d{2}:\d{2}$/, "")}</div>
        <div className="text-[13px] text-muted-foreground">{formatTimeRange(item.fecha_inicio, item.fecha_fin)}</div>
      </div>
      <span className={`rounded-full px-3 py-1 text-[13px] font-bold ${style.className}`}>{style.label}</span>
      {item.estado !== "reservado" && (
        <Button
          type="button"
          variant="outline"
          disabled={pending}
          aria-label={item.estado === "bloqueado" ? "Volver a ofrecer este horario" : "Bloquear este horario"}
          onClick={() =>
            run(() => setAvailabilityStateAction(item.disponibilidad_id, item.estado === "bloqueado" ? "disponible" : "bloqueado"))
          }
          className={iconButton}
        >
          {item.estado === "bloqueado" ? (
            <RotateCcw aria-hidden="true" className="size-4" />
          ) : (
            <Ban aria-hidden="true" className="size-4" />
          )}
        </Button>
      )}
      <Button
        type="button"
        variant="outline"
        disabled={pending}
        aria-label="Eliminar este horario"
        onClick={() => run(() => deleteAvailabilityAction(item.disponibilidad_id))}
        className={iconButton}
      >
        <Trash2 aria-hidden="true" className="size-4" />
      </Button>
    </li>
  );
}

export function AvailabilityPanel({ mentorId, items }: { mentorId: number; items: Availability[] }) {
  return (
    <div className="flex flex-wrap items-start gap-6">
      <section className={`${card} min-w-0 flex-[1_1_520px]`}>
        <h2 className="mb-1 font-heading text-lg font-semibold">Tus horarios</h2>
        <p className="mb-3 text-sm leading-normal text-muted-foreground">
          Los emprendedores que tienes asignados solo pueden agendar dentro de estos horarios.
        </p>
        {items.length === 0 ? (
          <p className="py-4 text-sm text-muted-foreground">Aún no definiste horarios disponibles.</p>
        ) : (
          <ul>
            {items.map((item) => (
              <Row key={item.disponibilidad_id} item={item} />
            ))}
          </ul>
        )}
      </section>

      <aside className={`${card} min-w-[280px] flex-[0_1_380px]`}>
        <h2 className="mb-1 font-heading text-lg font-semibold">Agregar horario</h2>
        <p className="mb-5 text-sm leading-normal text-muted-foreground">
          Si el nuevo horario se solapa con otro, no se guarda y verás el motivo.
        </p>
        <AddForm mentorId={mentorId} />
      </aside>
    </div>
  );
}
