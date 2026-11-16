"use client";

import { LoaderCircle } from "lucide-react";

import { useRunner } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { updateAlertAction } from "../server/actions";
import type { Alert } from "../types";

/** Acciones de una alerta sin resolver: revisarla, atenderla o descartarla. */
export function AlertActions({ alert }: { alert: Alert }) {
  const { pending, run } = useRunner();
  const button = "h-11 rounded-xl border-border-strong px-3.5 text-[13px] font-semibold";
  return (
    <div className="flex flex-wrap justify-end gap-2">
      {pending && <LoaderCircle aria-hidden="true" className="mt-3.5 size-4 animate-spin text-muted-foreground" />}
      {alert.estado === "abierta" && (
        <Button
          type="button"
          variant="outline"
          disabled={pending}
          className={button}
          onClick={() => run(() => updateAlertAction(alert.alerta_id, "revisada"))}
        >
          Revisada
        </Button>
      )}
      <Button
        type="button"
        disabled={pending}
        className="h-11 rounded-xl px-3.5 text-[13px] font-bold"
        onClick={() => run(() => updateAlertAction(alert.alerta_id, "atendida"))}
      >
        Atendida
      </Button>
      <Button
        type="button"
        variant="outline"
        disabled={pending}
        className={button}
        onClick={() => run(() => updateAlertAction(alert.alerta_id, "descartada"))}
      >
        Descartar
      </Button>
    </div>
  );
}
