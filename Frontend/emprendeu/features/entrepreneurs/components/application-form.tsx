"use client";

import { useState, useTransition } from "react";
import { CheckCircle2, LoaderCircle } from "lucide-react";

import { Field, inputClass, textareaClass } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { submitApplicationAction } from "../server/actions";
import type { ApplicationResult } from "../types";

const EMPTY = {
  nombre: "",
  apellido: "",
  email: "",
  telefono: "",
  documento_identidad: "",
  nombre_emprendimiento: "",
  descripcion_emprendimiento: "",
  sector: "",
  sitio_web: "",
};

function FieldError({ id, message }: { id: string; message?: string }) {
  if (!message) return null;
  return (
    <span id={`${id}-error`} className="text-[13px] font-semibold text-destructive">
      {message}
    </span>
  );
}

/** Formulario público para postularse al programa (CU26). No pide iniciar sesión. */
export function ApplicationForm() {
  const [values, setValues] = useState(EMPTY);
  const [result, setResult] = useState<ApplicationResult | null>(null);
  const [pending, start] = useTransition();
  const errors = result?.fieldErrors ?? {};
  const set = (key: keyof typeof EMPTY) => (value: string) => setValues((v) => ({ ...v, [key]: value }));

  if (result?.ok) {
    return (
      <div role="status" className="rounded-2xl border border-border bg-card p-8 text-center">
        <CheckCircle2 aria-hidden="true" className="mx-auto mb-3 size-10 text-success-foreground" />
        <h2 className="font-heading text-2xl font-semibold">{result.message}</h2>
        <p className="mt-2 text-[15px] leading-normal text-muted-foreground">
          La coordinación del CIE-U revisará tu postulación. Si te admiten, te entregarán tus datos de acceso para entrar a
          la app.
        </p>
      </div>
    );
  }

  const text = (key: keyof typeof EMPTY, label: string, opts: { type?: string; hint?: string; autoComplete?: string } = {}) => (
    <Field label={label} hint={opts.hint}>
      {(id) => (
        <>
          <input
            id={id}
            type={opts.type ?? "text"}
            autoComplete={opts.autoComplete}
            value={values[key]}
            aria-invalid={errors[key] ? true : undefined}
            aria-describedby={errors[key] ? `${id}-error` : undefined}
            onChange={(e) => set(key)(e.target.value)}
            className={inputClass}
          />
          <FieldError id={id} message={errors[key]} />
        </>
      )}
    </Field>
  );

  return (
    <form
      noValidate
      className="flex flex-col gap-5 rounded-2xl border border-border bg-card p-6 sm:p-8"
      onSubmit={(e) => {
        e.preventDefault();
        start(async () => setResult(await submitApplicationAction(values)));
      }}
    >
      <div className="grid gap-5 sm:grid-cols-2">
        {text("nombre", "Nombre", { autoComplete: "given-name" })}
        {text("apellido", "Apellido", { autoComplete: "family-name" })}
      </div>
      {text("email", "Correo electrónico", { type: "email", autoComplete: "email" })}
      <div className="grid gap-5 sm:grid-cols-2">
        {text("telefono", "Teléfono", { type: "tel", hint: "Opcional.", autoComplete: "tel" })}
        {text("documento_identidad", "Documento de identidad", { hint: "Opcional. Cédula o carnet." })}
      </div>
      {text("nombre_emprendimiento", "Nombre de tu emprendimiento")}
      {text("sector", "Sector", { hint: "Opcional. Por ejemplo: textil, alimentos, tecnología." })}
      <Field label="Cuéntanos de tu emprendimiento" hint="Opcional. Qué ofreces y a quién.">
        {(id) => (
          <>
            <textarea
              id={id}
              value={values.descripcion_emprendimiento}
              onChange={(e) => set("descripcion_emprendimiento")(e.target.value)}
              className={textareaClass}
            />
            <FieldError id={id} message={errors.descripcion_emprendimiento} />
          </>
        )}
      </Field>
      {/* Campo trampa: fuera de pantalla, sin foco y ocultado a lectores de pantalla. */}
      <div aria-hidden="true" className="absolute -left-[9999px] h-0 w-0 overflow-hidden">
        <label>
          No llenes este campo
          <input
            type="text"
            name="sitio_web"
            tabIndex={-1}
            autoComplete="off"
            value={values.sitio_web}
            onChange={(e) => set("sitio_web")(e.target.value)}
          />
        </label>
      </div>
      {result && !result.ok && (
        <p role="alert" className="rounded-xl bg-[#ffe3e8] px-4 py-3 text-sm font-semibold text-[#8f0f25]">
          {result.message}
        </p>
      )}
      <Button type="submit" disabled={pending} className="h-[52px] rounded-xl text-base font-bold">
        {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
        Enviar postulación
      </Button>
    </form>
  );
}
