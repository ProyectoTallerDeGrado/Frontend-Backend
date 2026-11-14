"use client";

import { useState, useTransition } from "react";
import { Copy } from "lucide-react";

import { Field, FormError, textareaClass } from "@/components/forms/form-bits";
import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";

import { decideAdmissionAction } from "../server/actions";
import type { Decision } from "../schemas/entrepreneurs-schemas";
import type { DecisionResult } from "../types";

const OPTIONS: { value: Decision; label: string; hint: string }[] = [
  { value: "admitida", label: "Admitir", hint: "Crea la cuenta del postulante y su emprendimiento." },
  { value: "rechazada", label: "Rechazar", hint: "Requiere un motivo. Es definitivo." },
  { value: "pendiente", label: "Mantener pendiente", hint: "Solo anota una observación; se podrá decidir después." },
];

const CONFIRM: Record<Decision, string> = {
  admitida: "Se creará la cuenta y el emprendimiento. Esta decisión es definitiva.",
  rechazada: "La postulación quedará rechazada. Esta decisión es definitiva.",
  pendiente: "",
};

/** CU26 · Decisión del coordinador en dos pasos: elegir y confirmar. */
export function AdmissionDecisionForm({ id, applicant, hasDocument }: { id: number; applicant: string; hasDocument: boolean }) {
  const [decision, setDecision] = useState<Decision>("admitida");
  const [notes, setNotes] = useState("");
  const [confirming, setConfirming] = useState(false);
  const [result, setResult] = useState<DecisionResult | null>(null);
  const [pending, start] = useTransition();

  if (result?.ok) {
    return (
      <div className="flex flex-col gap-4">
        <p role="status" className="rounded-xl bg-success-tint px-4 py-3 text-sm font-semibold text-success-foreground">
          {result.message}
        </p>
        {result.temporaryPassword && (
          <div className="rounded-xl border border-border-strong p-4">
            <p className="text-sm font-semibold">Contraseña temporal de {applicant}</p>
            <p className="mt-1 text-[13px] leading-snug text-muted-foreground">
              Entrégasela por un canal seguro. No se volverá a mostrar.
            </p>
            <div className="mt-3 flex items-center gap-2">
              <code className="flex-1 rounded-lg bg-muted px-3 py-2.5 font-mono text-[15px] break-all">{result.temporaryPassword}</code>
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
      </div>
    );
  }

  const submit = () =>
    start(async () => {
      const r = await decideAdmissionAction(id, decision, notes);
      setResult(r);
      if (r.ok) toast.success(r.message);
      else {
        toast.error(r.message);
        setConfirming(false);
      }
    });

  return (
    <form
      noValidate
      className="flex flex-col gap-5"
      onSubmit={(e) => {
        e.preventDefault();
        if (decision === "pendiente" || confirming) submit();
        else setConfirming(true);
      }}
    >
      <fieldset className="flex flex-col gap-2" disabled={pending}>
        <legend className="mb-2 text-sm font-semibold">Decisión</legend>
        {OPTIONS.map((o) => (
          <label key={o.value} className="flex min-h-11 cursor-pointer items-start gap-3 rounded-xl border-[1.5px] border-border-strong bg-card px-4 py-3 has-[:checked]:border-primary has-[:checked]:bg-blue-50">
            <input
              type="radio"
              name="decision"
              value={o.value}
              checked={decision === o.value}
              onChange={() => {
                setDecision(o.value);
                setConfirming(false);
              }}
              className="mt-1 size-5 accent-[var(--primary)]"
            />
            <span>
              <span className="block text-[15px] font-semibold">{o.label}</span>
              <span className="block text-[13px] text-muted-foreground">{o.hint}</span>
            </span>
          </label>
        ))}
      </fieldset>
      {decision === "admitida" && !hasDocument && (
        <p role="alert" className="rounded-xl bg-[#fff0cc] px-4 py-3 text-sm font-semibold text-[#5e3f00]">
          La postulación no trae documento de identidad: faltan datos para admitirla.
        </p>
      )}
      <Field label={decision === "rechazada" ? "Motivo del rechazo" : "Observaciones (opcional)"}>
        {(fieldId) => (
          <textarea id={fieldId} value={notes} onChange={(e) => setNotes(e.target.value)} maxLength={2000} className={textareaClass} />
        )}
      </Field>
      {confirming && (
        <p role="alert" className="rounded-xl bg-blue-50 px-4 py-3 text-sm text-primary">
          <strong>¿Confirmas la decisión sobre {applicant}?</strong> {CONFIRM[decision]}
        </p>
      )}
      <FormError message={result && !result.ok ? result.message : null} />
      <div className="flex gap-3">
        {confirming && (
          <Button type="button" variant="outline" disabled={pending} onClick={() => setConfirming(false)} className="h-12 rounded-xl border-border-strong px-5 font-semibold">
            Volver
          </Button>
        )}
        <Button type="submit" disabled={pending} className="h-12 rounded-xl px-6 text-[15px] font-bold">
          {pending ? "Guardando…" : decision === "pendiente" || confirming ? "Confirmar decisión" : "Continuar"}
        </Button>
      </div>
    </form>
  );
}
