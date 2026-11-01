"use client";

import { useActionState, useState } from "react";
import { Copy, LoaderCircle, Plus, X } from "lucide-react";

import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Sheet, SheetClose, SheetContent, SheetTitle, SheetTrigger } from "@/components/ui/sheet";

import { ROLE_META } from "../roles";
import { createUserAction } from "../server/actions";
import type { NewUserState, Role } from "../types";

const initial: NewUserState = {};

function Form({ roles, onDone }: { roles: Role[]; onDone: () => void }) {
  const [state, action, pending] = useActionState(createUserAction, initial);
  const [role, setRole] = useState(state.values?.role || "emprendedor");
  const errors = state.errors ?? {};

  if (state.created) {
    const { name, temporaryPassword } = state.created;
    return (
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <p role="status" className="rounded-xl bg-success-tint px-4 py-3 text-sm font-semibold text-success-foreground">
          Usuario registrado: {name}.
        </p>
        {temporaryPassword && (
          <div className="rounded-xl border border-border-strong p-4">
            <p className="text-sm font-semibold">Contraseña temporal</p>
            <p className="mt-1 text-[13px] leading-snug text-muted-foreground">
              Compártela con la persona por un canal seguro. No se volverá a mostrar.
            </p>
            <div className="mt-3 flex items-center gap-2">
              <code className="flex-1 rounded-lg bg-muted px-3 py-2.5 font-mono text-[15px] break-all">
                {temporaryPassword}
              </code>
              <Button
                type="button"
                variant="outline"
                className="size-11 rounded-lg"
                aria-label="Copiar contraseña"
                onClick={() => {
                  void navigator.clipboard.writeText(temporaryPassword);
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
    <form action={action} noValidate className="flex min-h-0 flex-1 flex-col">
      <div className="flex flex-1 flex-col gap-5 overflow-y-auto px-7 py-6">
        <div className="flex flex-col gap-2">
          <Label htmlFor="nu-name" className="text-sm font-semibold">
            Nombre completo
          </Label>
          <Input
            key={state.values?.name ?? ""}
            id="nu-name"
            name="name"
            defaultValue={state.values?.name ?? ""}
            placeholder="Nombre y apellidos"
            aria-invalid={errors.name ? true : undefined}
            className="h-[50px] rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-base"
          />
          {errors.name && <span className="text-[13px] font-semibold text-destructive">{errors.name}</span>}
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="nu-email" className="text-sm font-semibold">
            Correo electrónico
          </Label>
          <Input
            key={state.values?.email ?? ""}
            id="nu-email"
            name="email"
            type="email"
            defaultValue={state.values?.email ?? ""}
            placeholder="nombre@uagrm.edu.bo"
            aria-invalid={errors.email ? true : undefined}
            className="h-[50px] rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-base"
          />
          {errors.email && <span className="text-[13px] font-semibold text-destructive">{errors.email}</span>}
        </div>
        <fieldset className="flex flex-col gap-2.5">
          <legend className="mb-1 text-sm font-semibold">Rol asignado</legend>
          <input type="hidden" name="role" value={role} />
          {roles.map((r) => {
            const on = role === r.nombre;
            return (
              <button
                key={r.rol_id}
                type="button"
                role="radio"
                aria-checked={on}
                onClick={() => setRole(r.nombre)}
                className={`flex min-h-14 items-center gap-3.5 rounded-xl border-2 px-4 py-2.5 text-left outline-none transition-all focus-visible:ring-3 focus-visible:ring-primary/30 ${on ? "border-primary bg-blue-50" : "border-border-strong bg-card"}`}
              >
                <span
                  className={`flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 ${on ? "border-primary" : "border-border-strong"}`}
                >
                  <span className={`size-2.5 rounded-full bg-primary transition-transform ${on ? "scale-100" : "scale-0"}`} />
                </span>
                <span className="text-[15px] font-semibold">{ROLE_META[r.nombre]?.label ?? r.nombre}</span>
              </button>
            );
          })}
          {errors.role && <span className="text-[13px] font-semibold text-destructive">{errors.role}</span>}
        </fieldset>
        <p className="text-[13px] leading-snug text-muted-foreground">
          El sistema genera una contraseña temporal que verás una sola vez al registrar.
        </p>
        {state.message && (
          <p role="alert" className="rounded-xl bg-[#ffe3e8] px-4 py-3 text-sm font-semibold text-[#8f0f25]">
            {state.message}
          </p>
        )}
      </div>
      <div className="flex gap-3 border-t border-border px-7 py-5">
        <SheetClose render={<Button type="button" variant="outline" className="h-[50px] flex-1 rounded-xl border-border-strong text-[15px] font-semibold" />}>
          Cancelar
        </SheetClose>
        <Button type="submit" disabled={pending} className="h-[50px] flex-[1.4] rounded-xl text-[15px] font-bold">
          {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
          Registrar usuario
        </Button>
      </div>
    </form>
  );
}

export function NewUserDrawer({ roles }: { roles: Role[] }) {
  const [open, setOpen] = useState(false);
  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger
        render={
          <Button className="h-12 gap-2 rounded-xl px-5 text-[15px] font-bold hover:-translate-y-0.5 hover:shadow-[0_10px_22px_-10px_rgba(31,79,214,.75)]" />
        }
      >
        <Plus aria-hidden="true" className="size-[18px]" strokeWidth={2.4} />
        Nuevo usuario
      </SheetTrigger>
      <SheetContent side="right" showCloseButton={false} className="w-full gap-0 p-0 sm:max-w-[460px]">
        <div className="flex items-center justify-between border-b border-border px-7 py-6">
          <SheetTitle className="font-heading text-xl font-semibold">Nuevo usuario</SheetTitle>
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
