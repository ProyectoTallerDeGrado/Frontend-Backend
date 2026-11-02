"use client";

import { useState } from "react";
import { Pencil, Plus } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, inputClass, textareaClass, useRunner } from "@/components/forms/form-bits";
import { boDay, boTime } from "@/lib/format";

import { MODALITIES } from "../schemas/training-schemas";
import { createTrainingAction, updateTrainingAction } from "../server/actions";
import type { Training } from "../types";

/** `datetime-local` en hora de Bolivia a partir del instante UTC guardado. */
function toLocalInput(iso: string | null): string {
  return iso ? `${boDay(iso)}T${boTime(new Date(iso))}` : "";
}

function Form({ training, onDone }: { training?: Training; onDone: () => void }) {
  const [titulo, setTitulo] = useState(training?.titulo ?? "");
  const [descripcion, setDescripcion] = useState(training?.descripcion ?? "");
  const [fecha, setFecha] = useState(toLocalInput(training?.fecha ?? null));
  const [modalidad, setModalidad] = useState(training?.modalidad ?? "");
  const [tipo, setTipo] = useState(training?.tipo ?? "");
  const { pending, error, run } = useRunner(onDone);

  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        const input = { titulo, descripcion, fecha, modalidad, tipo };
        run(() => (training ? updateTrainingAction(training.capacitacion_id, input) : createTrainingAction(input)));
      }}
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <Field label="Título">{(id) => <input id={id} value={titulo} onChange={(e) => setTitulo(e.target.value)} className={inputClass} />}</Field>
        <Field label="Descripción" hint="Opcional.">
          {(id) => <textarea id={id} value={descripcion} onChange={(e) => setDescripcion(e.target.value)} className={textareaClass} />}
        </Field>
        <Field label="Fecha y hora" hint="Hora de Bolivia. Es obligatoria para publicar.">
          {(id) => <input id={id} type="datetime-local" value={fecha} onChange={(e) => setFecha(e.target.value)} className={inputClass} />}
        </Field>
        <Field label="Modalidad" hint="Opcional.">
          {(id) => (
            <select id={id} value={modalidad} onChange={(e) => setModalidad(e.target.value)} className={inputClass}>
              <option value="">Sin definir</option>
              {MODALITIES.map((m) => (
                <option key={m} value={m}>
                  {m.charAt(0).toUpperCase() + m.slice(1)}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label="Tipo" hint="Opcional. Por ejemplo: taller, charla, curso.">
          {(id) => <input id={id} value={tipo} onChange={(e) => setTipo(e.target.value)} className={inputClass} />}
        </Field>
        {!training && (
          <p className="rounded-xl bg-blue-50 px-4 py-3 text-[13px] leading-snug">
            Se crea como borrador: los emprendedores no la ven hasta que la publiques.
          </p>
        )}
        <FormError message={error} />
      </div>
      <SheetFooter pending={pending} label={training ? "Guardar cambios" : "Crear capacitación"} />
    </form>
  );
}

export function NewTrainingSheet() {
  return (
    <FormSheet
      title="Nueva capacitación"
      trigger={
        <>
          <Plus aria-hidden="true" className="size-[18px]" strokeWidth={2.4} />
          Nueva capacitación
        </>
      }
    >
      {(close) => <Form onDone={close} />}
    </FormSheet>
  );
}

export function EditTrainingSheet({ training }: { training: Training }) {
  return (
    <FormSheet
      title="Editar capacitación"
      variant="outline"
      trigger={
        <>
          <Pencil aria-hidden="true" className="size-4" />
          Editar
        </>
      }
      triggerClassName="h-11 gap-1.5 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
    >
      {(close) => <Form training={training} onDone={close} />}
    </FormSheet>
  );
}
