"use client";

import { useId, useState, useTransition, type ReactNode } from "react";
import { LoaderCircle, X } from "lucide-react";

import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Sheet, SheetClose, SheetContent, SheetTitle, SheetTrigger } from "@/components/ui/sheet";

/** Resultado de una acción de servidor (lo devuelven las `actions.ts` de cada feature). */
export type ActionResult = { ok: boolean; message: string };

export const inputClass =
  "h-12 w-full rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-[15px] outline-none focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15 disabled:opacity-60";

export const textareaClass =
  "min-h-24 w-full resize-y rounded-xl border-[1.5px] border-border-strong bg-card px-4 py-3 text-[15px] leading-normal outline-none focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15";

/** Etiqueta asociada al control que recibe como hijo (le pasa el `id`). */
export function Field({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: (id: string) => ReactNode;
}) {
  const id = useId();
  return (
    <div className="flex flex-col gap-2">
      <Label htmlFor={id} className="text-sm font-semibold">
        {label}
      </Label>
      {children(id)}
      {hint && <span className="text-[13px] leading-snug text-muted-foreground">{hint}</span>}
    </div>
  );
}

/**
 * Ejecuta una acción de servidor, avisa con un toast y deja el mensaje de error a
 * mano para mostrarlo dentro del formulario (el toast queda tapado por la hoja lateral).
 */
export function useRunner(onOk?: () => void) {
  const [pending, start] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const run = (call: () => Promise<ActionResult>) =>
    start(async () => {
      setError(null);
      const result = await call();
      if (result.ok) {
        toast.success(result.message);
        onOk?.();
      } else {
        setError(result.message);
        toast.error(result.message);
      }
    });
  return { pending, error, run };
}

export function FormError({ message }: { message: string | null }) {
  if (!message) return null;
  return (
    <p role="alert" className="rounded-xl bg-danger-tint px-4 py-3 text-sm font-semibold text-danger-foreground">
      {message}
    </p>
  );
}

type FormSheetProps = {
  title: string;
  trigger: ReactNode;
  triggerClassName?: string;
  variant?: "default" | "outline";
  children: (close: () => void) => ReactNode;
};

/** Hoja lateral de 460 px (patrón del drawer «Nuevo usuario»). El contenido se monta al abrir. */
export function FormSheet({ title, trigger, triggerClassName, variant = "default", children }: FormSheetProps) {
  const [open, setOpen] = useState(false);
  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger
        render={
          <Button variant={variant} className={triggerClassName ?? "h-11 gap-2 rounded-xl px-4 text-sm font-bold"} />
        }
      >
        {trigger}
      </SheetTrigger>
      <SheetContent side="right" showCloseButton={false} className="w-full gap-0 p-0 sm:max-w-[460px]">
        <div className="flex items-center justify-between border-b border-border px-7 py-6">
          <SheetTitle className="font-heading text-xl font-semibold">{title}</SheetTitle>
          <SheetClose
            render={<Button type="button" variant="ghost" className="size-11 rounded-xl bg-muted" aria-label="Cerrar" />}
          >
            <X aria-hidden="true" className="size-5" />
          </SheetClose>
        </div>
        {open && children(() => setOpen(false))}
      </SheetContent>
    </Sheet>
  );
}

/** Pie con Cancelar y el botón principal de un formulario dentro de una hoja. */
export function SheetFooter({ pending, label }: { pending: boolean; label: string }) {
  return (
    <div className="flex gap-3 border-t border-border px-7 py-5">
      <SheetClose
        render={
          <Button
            type="button"
            variant="outline"
            className="h-[50px] flex-1 rounded-xl border-border-strong text-[15px] font-semibold"
          />
        }
      >
        Cancelar
      </SheetClose>
      <Button type="submit" disabled={pending} className="h-[50px] flex-[1.4] rounded-xl text-[15px] font-bold">
        {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
        {label}
      </Button>
    </div>
  );
}
