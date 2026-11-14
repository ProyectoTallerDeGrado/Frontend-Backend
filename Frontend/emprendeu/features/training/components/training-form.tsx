"use client";

import { useState } from "react";
import { Pencil, Plus } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, inputClass, textareaClass, useRunner } from "@/components/forms/form-bits";
import { boDay, boTime } from "@/lib/format";

import { createTrainingAction, updateTrainingAction } from "../server/actions";
import { TRAINING_STATES } from "../schemas/training-schemas";
import type { Training } from "../types";

function Form({ training, close }: { training?: Training; close: () => void }) {
  const [titulo, setTitulo] = useState(training?.titulo ?? "");
  const [descripcion, setDescripcion] = useState(training?.descripcion ?? "");
  const [day, setDay] = useState(training?.fecha ? boDay(training.fecha) : "");
  const [time, setTime] = useState(training?.fecha ? boTime(new Date(training.fecha)) : "09:00");
  const [modalidad, setModalidad] = useState(training?.modalidad ?? "");
  const [tipo, setTipo] = useState(training?.tipo ?? "");
  const [estado, setEstado] = useState(training?.estado ?? "programada");
  const { pending, error, run } = useRunner(close);

  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        const input = { titulo, descripcion, day, time, modalidad, tipo, ...(training ? { estado: estado as (typeof TRAINING_STATES)[number] } : {}) };
        run(() => (training ? updateTrainingAction(training.capacitacion_id, input) : createTrainingAction(input)));
      }}
    >
      <div className="flex flex-1 flex-col gap-4 overflow-y-auto px-7 py-6">
        <Field label="Título">
          {(id) => <input id={id} value={titulo} maxLength={240} onChange={(e) => setTitulo(e.target.value)} className={inputClass} />}
        </Field>
        <Field label="Descripción">
          {(id) => <textarea id={id} value={descripcion} onChange={(e) => setDescripcion(e.target.value)} className={textareaClass} />}
        </Field>
        <div className="flex gap-3">
          <div className="flex-1">
            <Field label="Día">
              {(id) => <input id={id} type="date" value={day} onChange={(e) => setDay(e.target.value)} className={inputClass} />}
            </Field>
          </div>
          <div className="flex-1">
            <Field label="Hora">
              {(id) => <input id={id} type="time" value={time} onChange={(e) => setTime(e.target.value)} className={inputClass} />}
            </Field>
          </div>
        </div>
        <Field label="Modalidad" hint="Por ejemplo: presencial o virtual.">
          {(id) => <input id={id} value={modalidad} maxLength={40} onChange={(e) => setModalidad(e.target.value)} className={inputClass} />}
        </Field>
        <Field label="Tipo" hint="Por ejemplo: taller, charla o curso.">
          {(id) => <input id={id} value={tipo} maxLength={60} onChange={(e) => setTipo(e.target.value)} className={inputClass} />}
        </Field>
        {training && (
          <Field label="Estado">
            {(id) => (
              <select id={id} value={estado} onChange={(e) => setEstado(e.target.value)} className={inputClass}>
                {TRAINING_STATES.map((s) => (
                  <option key={s} value={s}>
                    {s.charAt(0).toUpperCase() + s.slice(1)}
                  </option>
                ))}
              </select>
            )}
          </Field>
        )}
        <FormError message={error} />
      </div>
      <SheetFooter pending={pending} label={training ? "Guardar cambios" : "Crear capacitación"} />
    </form>
  );
}

/** Hoja lateral para crear o editar una capacitación (CU27). */
export function TrainingFormSheet({ training }: { training?: Training }) {
  return training ? (
    <FormSheet
      title="Editar capacitación"
      variant="outline"
      triggerClassName="h-11 gap-2 rounded-xl border-border-strong px-4 text-sm font-semibold"
      trigger={
        <>
          <Pencil aria-hidden="true" className="size-4" /> Editar
        </>
      }
    >
      {(close) => <Form training={training} close={close} />}
    </FormSheet>
  ) : (
    <FormSheet
      title="Nueva capacitación"
      trigger={
        <>
          <Plus aria-hidden="true" className="size-[18px]" /> Nueva capacitación
        </>
      }
    >
      {(close) => <Form close={close} />}
    </FormSheet>
  );
}
