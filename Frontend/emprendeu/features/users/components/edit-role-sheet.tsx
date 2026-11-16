"use client";

import { useState } from "react";
import { Pencil } from "lucide-react";

import { Field, FormError, FormSheet, SheetFooter, inputClass, useRunner } from "@/components/forms/form-bits";

import { editRoleAction } from "../server/actions";
import type { Role } from "../types";

function Form({ role, onDone }: { role: Role; onDone: () => void }) {
  const [nombre, setNombre] = useState(role.nombre);
  const [descripcion, setDescripcion] = useState(role.descripcion ?? "");
  const { pending, error, run } = useRunner(onDone);
  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        run(() => editRoleAction(role.rol_id, { nombre, descripcion }));
      }}
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <Field label="Nombre del rol">
          {(id) => <input id={id} value={nombre} onChange={(e) => setNombre(e.target.value)} className={inputClass} />}
        </Field>
        <Field label="Descripción (opcional)">
          {(id) => <input id={id} value={descripcion} onChange={(e) => setDescripcion(e.target.value)} className={inputClass} />}
        </Field>
        <FormError message={error} />
      </div>
      <SheetFooter pending={pending} label="Guardar cambios" />
    </form>
  );
}

/** CU03: renombrar un rol personalizado (los del sistema no se pueden renombrar). */
export function EditRoleSheet({ role }: { role: Role }) {
  return (
    <FormSheet
      title="Editar rol"
      variant="outline"
      triggerClassName="h-11 gap-2 rounded-xl border-border-strong px-4 text-sm font-semibold"
      trigger={
        <>
          <Pencil aria-hidden="true" className="size-4" /> Renombrar
        </>
      }
    >
      {(close) => <Form role={role} onDone={close} />}
    </FormSheet>
  );
}
