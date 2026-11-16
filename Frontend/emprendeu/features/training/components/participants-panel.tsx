"use client";

import { useEffect, useState } from "react";
import { Check, LoaderCircle, UserPlus, X } from "lucide-react";

import { Field, FormError, inputClass, useRunner } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { addParticipantAction, searchEntrepreneursAction, setAttendanceAction } from "../server/actions";
import type { Participant } from "../types";

const card = "rounded-2xl border border-border bg-card p-6";

function Row({ trainingId, participant, name, canEdit }: { trainingId: number; participant: Participant; name: string; canEdit: boolean }) {
  const { pending, run } = useRunner();
  const a = participant.asistencia;
  return (
    <li className="flex flex-wrap items-center gap-x-4 gap-y-2 border-t border-muted py-3 first:border-t-0">
      <span className="min-w-0 flex-1 text-[15px] font-semibold">{name}</span>
      <span
        className={`rounded-full px-3 py-1 text-[13px] font-bold ${a === true ? "bg-success-tint text-success-foreground" : a === false ? "bg-danger-tint text-danger-foreground" : "bg-muted text-muted-foreground"}`}
      >
        {a === true ? "Asistió" : a === false ? "No asistió" : "Sin registrar"}
      </span>
      {canEdit && (
        <>
          <Button
            type="button"
            variant="outline"
            disabled={pending || a === true}
            aria-label={`Marcar asistencia de ${name}`}
            className="size-11 rounded-xl border-border-strong"
            onClick={() => run(() => setAttendanceAction(trainingId, participant.emprendedor_id, true))}
          >
            <Check aria-hidden="true" className="size-4" />
          </Button>
          <Button
            type="button"
            variant="outline"
            disabled={pending || a === false}
            aria-label={`Marcar ausencia de ${name}`}
            className="size-11 rounded-xl border-border-strong"
            onClick={() => run(() => setAttendanceAction(trainingId, participant.emprendedor_id, false))}
          >
            <X aria-hidden="true" className="size-4" />
          </Button>
        </>
      )}
    </li>
  );
}

type Option = { id: number; name: string };

function AddForm({ trainingId, enrolled }: { trainingId: number; enrolled: Set<number> }) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<Option[]>([]);
  const [chosen, setChosen] = useState<Option | null>(null);
  const { pending, error, run } = useRunner(() => {
    setChosen(null);
    setQuery("");
  });

  // Busca mientras escribe (con una pausa para no llamar en cada tecla).
  useEffect(() => {
    if (chosen) return;
    let cancelled = false;
    const timer = setTimeout(async () => {
      const found = await searchEntrepreneursAction(query);
      if (!cancelled) setResults(found.filter((o) => !enrolled.has(o.id)));
    }, 250);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [query, chosen, enrolled]);

  return (
    <form
      noValidate
      className="flex flex-col gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        if (chosen) run(() => addParticipantAction(trainingId, chosen.id));
      }}
    >
      <Field label="Buscar emprendedor" hint="Por nombre, correo o documento.">
        {(fid) => (
          <input
            id={fid}
            value={chosen ? chosen.name : query}
            onChange={(e) => {
              setChosen(null);
              setQuery(e.target.value);
            }}
            autoComplete="off"
            className={inputClass}
          />
        )}
      </Field>
      {!chosen && (
        <ul aria-label="Resultados" className="flex max-h-56 flex-col overflow-y-auto rounded-xl border border-border">
          {results.length === 0 && <li className="px-4 py-3 text-sm text-muted-foreground">Sin resultados.</li>}
          {results.map((o) => (
            <li key={o.id} className="border-t border-muted first:border-t-0">
              <button
                type="button"
                onClick={() => setChosen(o)}
                className="min-h-11 w-full px-4 py-2 text-left text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:bg-blue-50"
              >
                {o.name}
              </button>
            </li>
          ))}
        </ul>
      )}
      <FormError message={error} />
      <Button type="submit" disabled={pending || !chosen} className="h-12 gap-2 self-start rounded-xl px-6 text-[15px] font-bold">
        {pending ? <LoaderCircle aria-hidden="true" className="size-4 animate-spin" /> : <UserPlus aria-hidden="true" className="size-[18px]" />}
        Agregar participante
      </Button>
    </form>
  );
}

/** CU28 · Participantes de una capacitación y registro de asistencia. */
export function ParticipantsPanel({
  trainingId,
  participants,
  canEdit,
  canAdd,
  closed,
}: {
  trainingId: number;
  participants: Participant[];
  canEdit: boolean;
  canAdd: boolean;
  closed: boolean;
}) {
  const enrolled = new Set(participants.map((p) => p.emprendedor_id));
  return (
    <div className="flex flex-wrap items-start gap-6">
      <section className={`${card} min-w-0 flex-[1_1_520px]`}>
        <h2 className="mb-3 font-heading text-lg font-semibold">Participantes ({participants.length})</h2>
        {participants.length === 0 ? (
          <p className="py-4 text-sm text-muted-foreground">Aún no hay participantes inscritos.</p>
        ) : (
          <ul>
            {participants.map((p) => (
              <Row
                key={p.capacitacion_participante_id}
                trainingId={trainingId}
                participant={p}
                name={p.nombre ?? `Emprendedor #${p.emprendedor_id}`}
                canEdit={canEdit}
              />
            ))}
          </ul>
        )}
      </section>
      {canAdd && (
        <aside className={`${card} min-w-[280px] flex-[0_1_380px]`}>
          <h2 className="mb-1 font-heading text-lg font-semibold">Agregar participante</h2>
          {closed ? (
            <p className="text-sm text-muted-foreground">La capacitación fue cancelada: ya no admite participantes.</p>
          ) : (
            <>
              <p className="mb-5 text-sm leading-normal text-muted-foreground">Un emprendedor no puede repetirse en la misma capacitación.</p>
              <AddForm trainingId={trainingId} enrolled={enrolled} />
            </>
          )}
        </aside>
      )}
    </div>
  );
}
