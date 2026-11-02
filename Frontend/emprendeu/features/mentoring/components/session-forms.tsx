"use client";

import { useState } from "react";
import { CircleCheck, ClipboardPlus, Handshake, Lightbulb } from "lucide-react";

import { boDay, boTime } from "@/lib/format";

import { commitAction, completeSessionAction, recommendAction, registerSessionAction } from "../server/actions";
import type { Participant, Session, VentureOption } from "../types";
import { Field, FormError, FormSheet, SheetFooter, inputClass, textareaClass, useRunner } from "@/components/forms/form-bits";

const body = "flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6";
const form = "flex min-h-0 flex-1 flex-col";

function ModalitySelect({ id, value, onChange }: { id: string; value: string; onChange: (v: string) => void }) {
  return (
    <select id={id} value={value} onChange={(e) => onChange(e.target.value)} className={inputClass}>
      <option value="presencial">Presencial</option>
      <option value="virtual">Virtual</option>
      <option value="hibrida">Híbrida</option>
    </select>
  );
}

/** Fecha y hora de algo que ya ocurrió: por defecto, ahora (hora de Bolivia). */
function WhenFields({
  date,
  time,
  onDate,
  onTime,
}: {
  date: string;
  time: string;
  onDate: (v: string) => void;
  onTime: (v: string) => void;
}) {
  return (
    <div className="flex gap-3">
      <div className="flex-[1.3]">
        <Field label="Fecha realizada">
          {(id) => <input id={id} type="date" max={boDay()} value={date} onChange={(e) => onDate(e.target.value)} className={inputClass} />}
        </Field>
      </div>
      <div className="flex-1">
        <Field label="Hora">
          {(id) => <input id={id} type="time" value={time} onChange={(e) => onTime(e.target.value)} className={inputClass} />}
        </Field>
      </div>
    </div>
  );
}

// --- CU16 · registrar una sesión ya realizada (no agendada en la app) --------------

function RegisterForm({ ventures, onDone }: { ventures: VentureOption[]; onDone: () => void }) {
  const [ventureId, setVentureId] = useState(ventures.length === 1 ? String(ventures[0].id) : "");
  const [date, setDate] = useState(boDay());
  const [time, setTime] = useState(boTime());
  const [tema, setTema] = useState("");
  const [modalidad, setModalidad] = useState("presencial");
  const [observaciones, setObservaciones] = useState("");
  const { pending, error, run } = useRunner(onDone);

  return (
    <form
      noValidate
      className={form}
      onSubmit={(e) => {
        e.preventDefault();
        run(() =>
          registerSessionAction({ ventureId: Number(ventureId) || NaN, date, time, tema, modalidad, observaciones }),
        );
      }}
    >
      <div className={body}>
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
        <WhenFields date={date} time={time} onDate={setDate} onTime={setTime} />
        <Field label="Tema">
          {(id) => <input id={id} value={tema} onChange={(e) => setTema(e.target.value)} placeholder="Ej. Estructura de costos" className={inputClass} />}
        </Field>
        <Field label="Modalidad">{(id) => <ModalitySelect id={id} value={modalidad} onChange={setModalidad} />}</Field>
        <Field label="Observaciones" hint="Opcional.">
          {(id) => <textarea id={id} value={observaciones} onChange={(e) => setObservaciones(e.target.value)} className={textareaClass} />}
        </Field>
        <FormError message={error} />
      </div>
      <SheetFooter pending={pending} label="Registrar sesión" />
    </form>
  );
}

export function RegisterSessionSheet({ ventures }: { ventures: VentureOption[] }) {
  return (
    <FormSheet
      title="Registrar sesión realizada"
      trigger={
        <>
          <ClipboardPlus aria-hidden="true" className="size-[18px]" strokeWidth={2.2} />
          Registrar sesión
        </>
      }
      triggerClassName="h-12 gap-2 rounded-xl px-5 text-[15px] font-bold"
    >
      {(close) => <RegisterForm ventures={ventures} onDone={close} />}
    </FormSheet>
  );
}

// --- CU16 · completar una sesión agendada -------------------------------------------

function CompleteForm({ session, onDone }: { session: Session; onDone: () => void }) {
  const [date, setDate] = useState(boDay());
  const [time, setTime] = useState(boTime());
  const [tema, setTema] = useState(session.tema ?? "");
  const [modalidad, setModalidad] = useState(session.modalidad ?? "presencial");
  const [observaciones, setObservaciones] = useState("");
  const { pending, error, run } = useRunner(onDone);

  return (
    <form
      noValidate
      className={form}
      onSubmit={(e) => {
        e.preventDefault();
        run(() => completeSessionAction(session.sesion_id, { date, time, tema, modalidad, observaciones }));
      }}
    >
      <div className={body}>
        <p className="text-sm leading-normal text-muted-foreground">
          Sesión con <strong>{session.emprendimiento ?? `emprendimiento ${session.emprendimiento_id}`}</strong>. Confirma
          cuándo se realizó y qué se trató.
        </p>
        <WhenFields date={date} time={time} onDate={setDate} onTime={setTime} />
        <Field label="Tema">
          {(id) => <input id={id} value={tema} onChange={(e) => setTema(e.target.value)} className={inputClass} />}
        </Field>
        <Field label="Modalidad">{(id) => <ModalitySelect id={id} value={modalidad} onChange={setModalidad} />}</Field>
        <Field label="Observaciones" hint="Opcional.">
          {(id) => <textarea id={id} value={observaciones} onChange={(e) => setObservaciones(e.target.value)} className={textareaClass} />}
        </Field>
        <FormError message={error} />
      </div>
      <SheetFooter pending={pending} label="Marcar como realizada" />
    </form>
  );
}

export function CompleteSessionSheet({ session }: { session: Session }) {
  return (
    <FormSheet
      title="Registrar sesión realizada"
      variant="outline"
      trigger={
        <>
          <CircleCheck aria-hidden="true" className="size-4" />
          Realizada
        </>
      }
      triggerClassName="h-11 gap-1.5 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
    >
      {(close) => <CompleteForm session={session} onDone={close} />}
    </FormSheet>
  );
}

// --- CU17 · recomendación de la sesión ----------------------------------------------

function RecommendForm({ session, onDone }: { session: Session; onDone: () => void }) {
  const [titulo, setTitulo] = useState("");
  const [contenido, setContenido] = useState("");
  const { pending, error, run } = useRunner(onDone);

  return (
    <form
      noValidate
      className={form}
      onSubmit={(e) => {
        e.preventDefault();
        run(() =>
          recommendAction({
            ventureId: session.emprendimiento_id,
            sessionId: session.sesion_id,
            titulo,
            contenido,
          }),
        );
      }}
    >
      <div className={body}>
        <p className="text-sm leading-normal text-muted-foreground">
          Queda vinculada a esta sesión de <strong>{session.emprendimiento ?? `emprendimiento ${session.emprendimiento_id}`}</strong>.
        </p>
        <Field label="Título">
          {(id) => <input id={id} value={titulo} onChange={(e) => setTitulo(e.target.value)} className={inputClass} />}
        </Field>
        <Field label="Recomendación">
          {(id) => <textarea id={id} value={contenido} onChange={(e) => setContenido(e.target.value)} className={`${textareaClass} min-h-36`} />}
        </Field>
        <FormError message={error} />
      </div>
      <SheetFooter pending={pending} label="Guardar recomendación" />
    </form>
  );
}

export function RecommendSheet({ session }: { session: Session }) {
  return (
    <FormSheet
      title="Nueva recomendación"
      variant="outline"
      trigger={
        <>
          <Lightbulb aria-hidden="true" className="size-4" />
          Recomendar
        </>
      }
      triggerClassName="h-11 gap-1.5 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
    >
      {(close) => <RecommendForm session={session} onDone={close} />}
    </FormSheet>
  );
}

// --- CU18 · compromiso con responsable del emprendimiento --------------------------

function CommitForm({ session, onDone }: { session: Session; onDone: () => void }) {
  // Quienes participaron en la sesión: emprendedores del emprendimiento y el asesor.
  const people: Participant[] = session.participantes;
  const learner = people.find((p) => p.rol === "emprendedor");
  const [responsible, setResponsible] = useState(learner ? String(learner.usuario_id) : "");
  const [descripcion, setDescripcion] = useState("");
  const [dueDate, setDueDate] = useState("");
  const { pending, error, run } = useRunner(onDone);

  return (
    <form
      noValidate
      className={form}
      onSubmit={(e) => {
        e.preventDefault();
        run(() =>
          commitAction({
            ventureId: session.emprendimiento_id,
            sessionId: session.sesion_id,
            responsibleId: Number(responsible) || NaN,
            descripcion,
            dueDate,
          }),
        );
      }}
    >
      <div className={body}>
        <p className="text-sm leading-normal text-muted-foreground">
          El responsable debe ser un emprendedor del emprendimiento o un asesor asignado.
        </p>
        <Field label="Responsable">
          {(id) => (
            <select id={id} value={responsible} onChange={(e) => setResponsible(e.target.value)} className={inputClass}>
              <option value="">Elige al responsable</option>
              {people.map((p) => (
                <option key={p.usuario_id} value={p.usuario_id}>
                  {p.nombre ?? `Usuario ${p.usuario_id}`} · {p.rol === "mentor" ? "Asesor" : "Emprendedor"}
                </option>
              ))}
            </select>
          )}
        </Field>
        <Field label="Compromiso">
          {(id) => <textarea id={id} value={descripcion} onChange={(e) => setDescripcion(e.target.value)} className={textareaClass} />}
        </Field>
        <Field label="Fecha límite" hint="Opcional. Si la dejas vacía se usa el plazo por defecto de los parámetros de seguimiento.">
          {(id) => <input id={id} type="date" min={boDay()} value={dueDate} onChange={(e) => setDueDate(e.target.value)} className={inputClass} />}
        </Field>
        <FormError message={error} />
      </div>
      <SheetFooter pending={pending} label="Guardar compromiso" />
    </form>
  );
}

export function CommitSheet({ session }: { session: Session }) {
  return (
    <FormSheet
      title="Nuevo compromiso"
      variant="outline"
      trigger={
        <>
          <Handshake aria-hidden="true" className="size-4" />
          Compromiso
        </>
      }
      triggerClassName="h-11 gap-1.5 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
    >
      {(close) => <CommitForm session={session} onDone={close} />}
    </FormSheet>
  );
}
