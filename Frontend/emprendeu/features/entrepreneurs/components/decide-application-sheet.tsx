"use client";

import { useState, useTransition } from "react";
import { Copy } from "lucide-react";

import { FormError, FormSheet, textareaClass } from "@/components/forms/form-bits";
import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";
import { formatDateTime } from "@/lib/format";

import { admitApplicationAction, rejectApplicationAction } from "../server/actions";
import type { Application, DecisionResult } from "../types";

function Row({ label, value }: { label: string; value: string | null }) {
  return (
    <div className="flex flex-col gap-0.5">
      <dt className="text-[12px] font-bold tracking-[.06em] text-muted-foreground uppercase">{label}</dt>
      <dd className="text-[15px] leading-snug whitespace-pre-line">{value || "—"}</dd>
    </div>
  );
}

function Body({ application, canDecide, onDone }: { application: Application; canDecide: boolean; onDone: () => void }) {
  const [notes, setNotes] = useState("");
  const [result, setResult] = useState<DecisionResult | null>(null);
  const [pending, start] = useTransition();
  const decided = application.estado !== "pendiente";

  const decide = (action: (id: number, notes: string) => Promise<DecisionResult>) =>
    start(async () => {
      const r = await action(application.postulacion_id, notes);
      setResult(r);
      if (r.ok) toast.success(r.message);
      else toast.error(r.message);
    });

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
              Entrégala a {application.nombre} por un canal seguro; con {application.email} ya puede entrar a la app. No se
              volverá a mostrar.
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
        <Button type="button" onClick={onDone} className="h-[50px] rounded-xl text-[15px] font-bold">
          Listo
        </Button>
      </div>
    );
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <dl className="flex flex-col gap-4">
          <Row label="Postulante" value={`${application.nombre} ${application.apellido}`} />
          <Row label="Correo" value={application.email} />
          <Row label="Teléfono" value={application.telefono} />
          <Row label="Documento de identidad" value={application.documento_identidad} />
          <Row label="Emprendimiento" value={application.nombre_emprendimiento} />
          <Row label="Sector" value={application.sector} />
          <Row label="Descripción" value={application.descripcion_emprendimiento} />
          <Row label="Postuló" value={formatDateTime(application.fecha_postulacion)} />
        </dl>
        {decided && (
          <div className="rounded-xl bg-muted px-4 py-3 text-sm leading-snug">
            <strong>{application.estado === "admitida" ? "Admitida" : "Rechazada"}</strong>
            {application.fecha_decision && ` el ${formatDateTime(application.fecha_decision)}`}
            {application.decidido_por && ` por ${application.decidido_por}`}.
            {application.observaciones_decision && <> Observación: {application.observaciones_decision}</>}
            <div className="mt-1 text-muted-foreground">Una decisión no se puede cambiar.</div>
          </div>
        )}
        {!decided && canDecide && (
          <>
            <label className="flex flex-col gap-2 text-sm font-semibold">
              Observaciones
              <textarea value={notes} onChange={(e) => setNotes(e.target.value)} className={textareaClass} />
              <span className="text-[13px] font-normal text-muted-foreground">
                Opcional al admitir; obligatoria al rechazar (queda guardada).
              </span>
            </label>
            <p className="rounded-xl bg-blue-50 px-4 py-3 text-[13px] leading-snug">
              Al admitir se crean juntos el usuario, el emprendedor y su emprendimiento. Si algo falla, no se crea nada.
            </p>
          </>
        )}
        <FormError message={result && !result.ok ? result.message : null} />
      </div>
      {!decided && canDecide && (
        <div className="flex gap-3 border-t border-border px-7 py-5">
          <Button
            type="button"
            variant="outline"
            disabled={pending}
            onClick={() => decide(rejectApplicationAction)}
            className="h-[50px] flex-1 rounded-xl border-border-strong text-[15px] font-semibold"
          >
            Rechazar
          </Button>
          <Button
            type="button"
            disabled={pending}
            onClick={() => decide(admitApplicationAction)}
            className="h-[50px] flex-[1.4] rounded-xl text-[15px] font-bold"
          >
            Admitir
          </Button>
        </div>
      )}
    </div>
  );
}

export function DecideApplicationSheet({ application, canDecide }: { application: Application; canDecide: boolean }) {
  const pendingState = application.estado === "pendiente";
  return (
    <FormSheet
      title={`Postulación de ${application.nombre}`}
      variant="outline"
      trigger={pendingState && canDecide ? "Revisar" : "Ver"}
      triggerClassName="h-11 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
    >
      {(close) => <Body application={application} canDecide={canDecide} onDone={close} />}
    </FormSheet>
  );
}
