"use client";

import { useState, useTransition } from "react";
import { LoaderCircle, Plus, X } from "lucide-react";

import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Sheet, SheetClose, SheetContent, SheetTitle, SheetTrigger } from "@/components/ui/sheet";

import { ROLE_TEMPLATES, roleLabel } from "../roles";
import { createRoleAction } from "../server/actions";
import type { Role } from "../types";

function Form({ roles, onDone }: { roles: Role[]; onDone: () => void }) {
  const [nombre, setNombre] = useState("");
  const [descripcion, setDescripcion] = useState("");
  const [plantilla, setPlantilla] = useState<"vacio" | "lectura">("lectura");
  const [clonarDe, setClonarDe] = useState<number | null>(null);
  const [pending, startTransition] = useTransition();

  const submit = () =>
    startTransition(async () => {
      const result = await createRoleAction({ nombre, descripcion, plantilla, clonarDe });
      if (result.ok) {
        toast.success(result.message);
        onDone();
      } else {
        toast.error(result.message);
      }
    });

  return (
    <form
      noValidate
      onSubmit={(e) => {
        e.preventDefault();
        submit();
      }}
      className="flex min-h-0 flex-1 flex-col"
    >
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <div className="flex flex-col gap-2">
          <Label htmlFor="nr-name" className="text-sm font-semibold">
            Nombre del rol
          </Label>
          <Input
            id="nr-name"
            value={nombre}
            onChange={(e) => setNombre(e.target.value)}
            placeholder="p. ej. auditor"
            className="h-13 rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-base"
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="nr-desc" className="text-sm font-semibold">
            Descripción (opcional)
          </Label>
          <Input
            id="nr-desc"
            value={descripcion}
            onChange={(e) => setDescripcion(e.target.value)}
            className="h-13 rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-base"
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="nr-clone" className="text-sm font-semibold">
            Copiar permisos de
          </Label>
          <select
            id="nr-clone"
            value={clonarDe ?? ""}
            onChange={(e) => setClonarDe(e.target.value ? Number(e.target.value) : null)}
            className="h-13 rounded-xl border-[1.5px] border-border-strong bg-card px-3 text-base"
          >
            <option value="">Ningún rol (empezar con una plantilla)</option>
            {roles.map((r) => (
              <option key={r.rol_id} value={r.rol_id}>
                {roleLabel(r.nombre)}
              </option>
            ))}
          </select>
        </div>
        {clonarDe === null && (
          <fieldset className="flex flex-col gap-2">
            <legend className="mb-1 text-sm font-semibold">Plantilla</legend>
            {ROLE_TEMPLATES.map((t) => (
              <label key={t.key} className="flex min-h-11 items-center gap-3 text-[15px]">
                <input
                  type="radio"
                  name="plantilla"
                  checked={plantilla === t.key}
                  onChange={() => setPlantilla(t.key)}
                  className="size-4"
                />
                {t.label}
              </label>
            ))}
          </fieldset>
        )}
        <p className="text-[13px] leading-snug text-muted-foreground">
          Después podrás ajustar la matriz y asignar el rol a un usuario desde Usuarios.
        </p>
      </div>
      <div className="flex gap-3 border-t border-border px-7 py-5">
        <SheetClose
          render={<Button type="button" variant="outline" className="h-13 flex-1 rounded-xl border-border-strong text-[15px] font-semibold" />}
        >
          Cancelar
        </SheetClose>
        <Button type="submit" disabled={pending} className="h-13 flex-[1.4] rounded-xl text-[15px] font-bold">
          {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
          Crear rol
        </Button>
      </div>
    </form>
  );
}

export function NewRoleDrawer({ roles }: { roles: Role[] }) {
  const [open, setOpen] = useState(false);
  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger render={<Button variant="outline" className="h-11 gap-2 rounded-xl px-4 text-sm font-bold" />}>
        <Plus aria-hidden="true" className="size-4" strokeWidth={2.4} />
        Nuevo rol
      </SheetTrigger>
      <SheetContent side="right" showCloseButton={false} className="w-full gap-0 p-0 sm:max-w-[460px]">
        <div className="flex items-center justify-between border-b border-border px-7 py-6">
          <SheetTitle className="font-heading text-xl font-semibold">Nuevo rol</SheetTitle>
          <SheetClose
            render={<Button type="button" variant="ghost" className="size-11 rounded-xl bg-muted" aria-label="Cerrar" />}
          >
            <X aria-hidden="true" className="size-5" />
          </SheetClose>
        </div>
        {open && <Form roles={roles} onDone={() => setOpen(false)} />}
      </SheetContent>
    </Sheet>
  );
}
