"use client";

import { Button } from "@/components/ui/button";
import { useRunner } from "@/components/forms/form-bits";

import { setAttendanceAction } from "../server/actions";

/** Marca asistió / no asistió; el botón del estado actual queda resaltado. */
export function AttendanceButtons({
  trainingId,
  emprendedorId,
  name,
  attended,
}: {
  trainingId: number;
  emprendedorId: number;
  name: string;
  attended: boolean | null;
}) {
  const { pending, run } = useRunner();
  return (
    <div className="flex justify-end gap-2" role="group" aria-label={`Asistencia de ${name}`}>
      <Button
        type="button"
        variant={attended === true ? "default" : "outline"}
        disabled={pending}
        aria-pressed={attended === true}
        onClick={() => run(() => setAttendanceAction(trainingId, emprendedorId, true, name))}
        className="h-11 rounded-xl px-3.5 text-sm font-semibold"
      >
        Asistió
      </Button>
      <Button
        type="button"
        variant={attended === false ? "default" : "outline"}
        disabled={pending}
        aria-pressed={attended === false}
        onClick={() => run(() => setAttendanceAction(trainingId, emprendedorId, false, name))}
        className="h-11 rounded-xl px-3.5 text-sm font-semibold"
      >
        No asistió
      </Button>
    </div>
  );
}
