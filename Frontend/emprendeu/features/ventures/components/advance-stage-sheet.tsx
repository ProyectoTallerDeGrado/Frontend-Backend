"use client";

import { useState } from "react";
import { ArrowRight } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, textareaClass, useRunner } from "@/components/forms/form-bits";

import { advanceVentureStageAction } from "../server/actions";
import type { Stage, Venture } from "../types";

function Form({ venture, next, onDone }: { venture: Venture; next: Stage; onDone: () => void }) {
  const [notes, setNotes] = useState("");
  const { pending, error, run } = useRunner(onDone);
  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        run(() => advanceVentureStageAction(venture.emprendimiento_id, next.etapa_id, notes, venture.nombre));
      }}
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <p className="text-sm leading-normal">
          <strong>{venture.nombre}</strong> pasará de{" "}
          <strong>{venture.etapa_actual?.nombre ?? "sin etapa"}</strong> a <strong>{next.nombre}</strong>. La etapa
          anterior queda en su historial y el cambio se registra en la auditoría.
        </p>
        {next.criterios && (
          <p className="rounded-xl bg-blue-50 px-4 py-3 text-[13px] leading-snug">
            <strong>Criterios de la etapa:</strong> {next.criterios}
          </p>
        )}
        <Field label="Observaciones" hint="Opcional. Por qué avanza ahora.">
          {(id) => <textarea id={id} value={notes} onChange={(e) => setNotes(e.target.value)} className={textareaClass} />}
        </Field>
        <FormError message={error} />
      </div>
      <SheetFooter pending={pending} label={`Pasar a ${next.nombre}`} />
    </form>
  );
}

export function AdvanceStageSheet({ venture, next }: { venture: Venture; next: Stage }) {
  return (
    <FormSheet
      title="Cambiar de etapa"
      variant="outline"
      trigger={
        <>
          Pasar a {next.nombre}
          <ArrowRight aria-hidden="true" className="size-4" />
        </>
      }
      triggerClassName="h-11 gap-1.5 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
    >
      {(close) => <Form venture={venture} next={next} onDone={close} />}
    </FormSheet>
  );
}
