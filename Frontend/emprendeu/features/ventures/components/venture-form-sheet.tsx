"use client";

import { useState } from "react";
import { Pencil, Plus } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, inputClass, textareaClass, useRunner } from "@/components/forms/form-bits";

import { createVentureAction, updateVentureAction } from "../server/actions";
import { VENTURE_STATES } from "../schemas/ventures-schemas";
import type { Venture } from "../types";

type Option = { id: number; name: string };

function Form({ venture, entrepreneurs, onDone }: { venture?: Venture; entrepreneurs: Option[]; onDone: () => void }) {
  const [name, setName] = useState(venture?.nombre ?? "");
  const [description, setDescription] = useState(venture?.descripcion ?? "");
  const [sector, setSector] = useState(venture?.sector ?? "");
  const [estado, setEstado] = useState(venture?.estado ?? "activo");
  const [entrepreneurId, setEntrepreneurId] = useState<number | null>(null);
  const { pending, error, run } = useRunner(onDone);
  const states = venture?.estado && !(VENTURE_STATES as readonly string[]).includes(venture.estado)
    ? [venture.estado, ...VENTURE_STATES]
    : [...VENTURE_STATES];

  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        const input = { name, description, sector, entrepreneurId, estado };
        run(() => (venture ? updateVentureAction(venture.emprendimiento_id, input) : createVentureAction(input)));
      }}
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        {!venture && (
          <Field label="Emprendedor" hint="Quién es el responsable del emprendimiento. Se registra como fundador.">
            {(id) => (
              <select
                id={id}
                value={entrepreneurId ?? ""}
                onChange={(e) => setEntrepreneurId(e.target.value ? Number(e.target.value) : null)}
                className={inputClass}
              >
                <option value="">Elige un emprendedor</option>
                {entrepreneurs.map((o) => (
                  <option key={o.id} value={o.id}>
                    {o.name}
                  </option>
                ))}
              </select>
            )}
          </Field>
        )}
        <Field label="Nombre del emprendimiento">
          {(id) => <input id={id} value={name} onChange={(e) => setName(e.target.value)} className={inputClass} />}
        </Field>
        <Field label="Sector" hint="Opcional. Por ejemplo: textil, alimentos, tecnología.">
          {(id) => <input id={id} value={sector} onChange={(e) => setSector(e.target.value)} className={inputClass} />}
        </Field>
        <Field label="Descripción" hint="Opcional.">
          {(id) => <textarea id={id} value={description} onChange={(e) => setDescription(e.target.value)} className={textareaClass} />}
        </Field>
        {venture && (
          <Field label="Estado" hint="Solo la coordinación cambia el estado.">
            {(id) => (
              <select id={id} value={estado} onChange={(e) => setEstado(e.target.value)} className={inputClass}>
                {states.map((s) => (
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
      <SheetFooter pending={pending} label={venture ? "Guardar cambios" : "Crear emprendimiento"} />
    </form>
  );
}

export function NewVentureSheet({ entrepreneurs }: { entrepreneurs: Option[] }) {
  return (
    <FormSheet
      title="Nuevo emprendimiento"
      trigger={
        <>
          <Plus aria-hidden="true" className="size-[18px]" strokeWidth={2.4} />
          Nuevo emprendimiento
        </>
      }
    >
      {(close) => <Form entrepreneurs={entrepreneurs} onDone={close} />}
    </FormSheet>
  );
}

export function EditVentureSheet({ venture }: { venture: Venture }) {
  return (
    <FormSheet
      title="Editar emprendimiento"
      variant="outline"
      trigger={
        <>
          <Pencil aria-hidden="true" className="size-4" />
          Editar
        </>
      }
      triggerClassName="h-11 gap-1.5 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
    >
      {(close) => <Form venture={venture} entrepreneurs={[]} onDone={close} />}
    </FormSheet>
  );
}
