import { CircleAlert, CircleCheck, Lock } from "lucide-react";
import type { ReactNode } from "react";

export function SecurityNotice({ children }: { children: ReactNode }) {
  return (
    <div className="mt-7 flex items-start gap-3 rounded-xl bg-blue-50 p-4 text-sm leading-normal text-foreground">
      <Lock aria-hidden="true" className="mt-px size-5 shrink-0 text-primary" />
      <span>{children}</span>
    </div>
  );
}

/** Error general del formulario (credenciales, red, servidor). */
export function ErrorNotice({ message }: { message: string }) {
  return (
    <p
      role="alert"
      className="flex items-start gap-2.5 rounded-xl bg-danger-tint px-4 py-3 text-sm font-semibold text-danger-foreground"
    >
      <CircleAlert aria-hidden="true" className="mt-px size-5 shrink-0" />
      {message}
    </p>
  );
}

export function SuccessNotice({ children }: { children: ReactNode }) {
  return (
    <p
      role="status"
      className="mb-6 flex items-start gap-2.5 rounded-xl bg-success-tint px-4 py-3 text-sm font-semibold text-success-foreground"
    >
      <CircleCheck aria-hidden="true" className="mt-px size-5 shrink-0" />
      <span>{children}</span>
    </p>
  );
}
