"use client";

import { useState, useTransition } from "react";
import { Copy, Plus } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, inputClass } from "@/components/forms/form-bits";
import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";

import { registerEntrepreneurAction } from "../server/actions";
import type { RegisterResult } from "../types";

function Form({ onDone }: { onDone: () => void }) {
  const [values, setValues] = useState({ name: "", email: "", document: "" });
  const [result, setResult] = useState<RegisterResult | null>(null);
  const [pending, start] = useTransition();
  const errors = result?.fieldErrors ?? {};

  if (result?.ok) {
    return (
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <p role="status" className="rounded-xl bg-success-tint px-4 py-3 text-sm font-semibold text-success-foreground">
          {result.message}
        </p>
        {result.temporaryPassword && (
          <div className="rounded-xl border border-border-strong p-4">
            <p className="text-sm font-semibold">Contraseña temporal</p>
            <p className="mt-1 text-[13px] leading-snug text-muted-foreground">
              Compártela con la persona por un canal seguro. No se volverá a mostrar.
            </p>
            <div className="mt-3 flex items-center gap-2">
              <code className="flex-1 rounded-lg bg-muted px-3 py-2.5 font-mono text-[15px] break-all">
                {result.temporaryPassword}
              </code>
              <Button
                type="button"
                variant="outline"
                className="size-11 rounded-lg"
                aria-label="Copiar contraseña"
                onClick={() => {
                  void navigator.clipboard.writeText(result.temporaryPassword ?? "");
                  toast.success("Contraseña copiada.");
                }}
              >
                <Copy aria-hidden="true" className="size-4" />
              </Button>
            </div>
          </div>
        )}
        <Button type="button" onClick={onDone} className="h-13 rounded-xl text-[15px] font-bold">
          Listo
        </Button>
      </div>
    );
  }

  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        start(async () => setResult(await registerEntrepreneurAction(values)));
      }}
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        {(
          [
            ["name", "Nombre completo", "Nombre y apellidos", "text"],
            ["email", "Correo electrónico", "nombre@uagrm.edu.bo", "email"],
            ["document", "Documento de identidad", "Cédula o carnet", "text"],
          ] as const
        ).map(([key, label, placeholder, type]) => (
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
                  onChange={(e) => setValues({ ...values, [key]: e.target.value })}
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
        ))}
        <p className="text-[13px] leading-snug text-muted-foreground">
          Se crea la cuenta y el perfil de emprendedor juntos. El sistema genera una contraseña temporal que verás una sola vez.
        </p>
        <FormError message={result && !result.ok && !result.fieldErrors ? result.message : null} />
      </div>
      <SheetFooter pending={pending} label="Registrar emprendedor" />
    </form>
  );
}

export function RegisterEntrepreneurSheet() {
  return (
    <FormSheet
      title="Nuevo emprendedor"
      trigger={
        <>
          <Plus aria-hidden="true" className="size-[18px]" strokeWidth={2.4} />
          Nuevo emprendedor
        </>
      }
    >
      {(close) => <Form onDone={close} />}
    </FormSheet>
  );
}
