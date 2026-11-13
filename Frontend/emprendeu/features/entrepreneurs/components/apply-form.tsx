"use client";

import { useState, useTransition } from "react";
import { CircleCheck, LoaderCircle } from "lucide-react";

import { Field, FormError, inputClass, textareaClass } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { applyAction } from "../server/actions";
import type { ApplyResult } from "../types";

const EMPTY = { nombre: "", apellido: "", email: "", telefono: "", documento: "", ventureName: "", sector: "", description: "" };

/** CU26 · Formulario público: la persona se postula al programa sin tener cuenta. */
export function ApplyForm() {
  const [values, setValues] = useState(EMPTY);
  const [result, setResult] = useState<ApplyResult | null>(null);
  const [pending, start] = useTransition();
  const errors = result?.fieldErrors ?? {};
  const set = (key: keyof typeof EMPTY) => (e: { target: { value: string } }) => setValues({ ...values, [key]: e.target.value });

  if (result?.ok) {
    return (
      <div role="status" className="flex flex-col items-start gap-3 rounded-2xl bg-success-tint p-6 text-success-foreground">
        <CircleCheck aria-hidden="true" className="size-8" />
        <p className="text-base font-semibold">{result.message}</p>
      </div>
    );
  }

  const text = (key: keyof typeof EMPTY, label: string, type = "text", placeholder?: string) => (
    <Field key={key} label={label}>
      {(id) => (
        <>
          <input
            id={id}
            type={type}
            value={values[key]}
            placeholder={placeholder}
            aria-invalid={errors[key] ? true : undefined}
            aria-describedby={errors[key] ? `${id}-error` : undefined}
            onChange={set(key)}
            className={inputClass}
          />
          {errors[key] && (
            <span id={`${id}-error`} className="text-[13px] font-semibold text-destructive">
              {errors[key]}
            </span>
          )}
        </>
      )}
    </Field>
  );

  return (
    <form
      noValidate
      className="flex flex-col gap-5"
      onSubmit={(e) => {
        e.preventDefault();
        start(async () => setResult(await applyAction(values)));
      }}
    >
      <div className="grid gap-5 sm:grid-cols-2">
        {text("nombre", "Nombre")}
        {text("apellido", "Apellidos")}
      </div>
      {text("email", "Correo electrónico", "email", "nombre@uagrm.edu.bo")}
      <div className="grid gap-5 sm:grid-cols-2">
        {text("documento", "Documento de identidad", "text", "Cédula o carnet")}
        {text("telefono", "Teléfono (opcional)", "tel")}
      </div>
      {text("ventureName", "Nombre de tu emprendimiento")}
      {text("sector", "Sector (opcional)")}
      <Field label="Cuéntanos de tu idea (opcional)">
        {(id) => <textarea id={id} value={values.description} onChange={set("description")} maxLength={4000} className={textareaClass} />}
      </Field>
      <FormError message={result && !result.ok && !result.fieldErrors ? result.message : null} />
      <Button type="submit" disabled={pending} className="h-[54px] gap-2 rounded-xl text-base font-bold">
        {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
        Enviar postulación
      </Button>
    </form>
  );
}
