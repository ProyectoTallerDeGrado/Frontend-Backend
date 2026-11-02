"use client";

import { useState } from "react";

import { inputClass, useRunner } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { addParticipantAction } from "../server/actions";

export function AddParticipantForm({ trainingId, options }: { trainingId: number; options: { id: number; name: string }[] }) {
  const [selected, setSelected] = useState("");
  const { pending, error, run } = useRunner(() => setSelected(""));
  return (
    <form
      className="mb-5 flex flex-wrap items-end gap-3"
      onSubmit={(e) => {
        e.preventDefault();
        if (selected) run(() => addParticipantAction(trainingId, Number(selected)));
      }}
    >
      <label className="flex min-w-[260px] flex-[1_1_320px] flex-col gap-1.5 text-[13px] font-semibold">
        Agregar participante
        <select value={selected} onChange={(e) => setSelected(e.target.value)} className={inputClass}>
          <option value="">Elige un emprendedor</option>
          {options.map((o) => (
            <option key={o.id} value={o.id}>
              {o.name}
            </option>
          ))}
        </select>
      </label>
      <Button type="submit" disabled={pending || !selected} className="h-12 rounded-xl px-5 text-[15px] font-bold">
        Agregar
      </Button>
      {error && (
        <p role="alert" className="w-full text-sm font-semibold text-destructive">
          {error}
        </p>
      )}
    </form>
  );
}
