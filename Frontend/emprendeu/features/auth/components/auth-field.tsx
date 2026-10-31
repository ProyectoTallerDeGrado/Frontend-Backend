"use client";

import { useId, useState } from "react";
import { Eye, EyeOff } from "lucide-react";

import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type AuthFieldProps = {
  name: string;
  label: string;
  type?: "text" | "email" | "password";
  placeholder?: string;
  autoComplete?: string;
  error?: string;
  defaultValue?: string;
};

/** Etiqueta + input + mensaje de error, con el estilo del diseño. */
export function AuthField({
  name,
  label,
  type = "text",
  placeholder,
  autoComplete,
  error,
  defaultValue,
}: AuthFieldProps) {
  const id = useId();
  const errorId = `${id}-error`;
  const [visible, setVisible] = useState(false);
  const isPassword = type === "password";

  return (
    <div className="flex flex-col gap-2">
      <Label htmlFor={id} className="text-sm font-semibold text-foreground">
        {label}
      </Label>
      <div className="relative">
        <Input
          // Al volver con valores del servidor se remonta: el input es no controlado.
          key={defaultValue ?? ""}
          id={id}
          name={name}
          type={isPassword && visible ? "text" : type}
          placeholder={placeholder}
          defaultValue={defaultValue}
          autoComplete={autoComplete}
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? errorId : undefined}
          className={`h-[52px] rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-base focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15 ${isPassword ? "pr-14" : ""}`}
        />
        {isPassword && (
          <button
            type="button"
            onClick={() => setVisible((v) => !v)}
            aria-label={visible ? "Ocultar contraseña" : "Mostrar contraseña"}
            aria-pressed={visible}
            className="absolute top-1/2 right-1 flex size-11 -translate-y-1/2 items-center justify-center rounded-lg text-muted-foreground outline-none hover:text-foreground focus-visible:ring-3 focus-visible:ring-primary/30"
          >
            {visible ? <EyeOff className="size-5" /> : <Eye className="size-5" />}
          </button>
        )}
      </div>
      {error && (
        <span id={errorId} className="text-[13px] font-semibold text-destructive">
          {error}
        </span>
      )}
    </div>
  );
}
