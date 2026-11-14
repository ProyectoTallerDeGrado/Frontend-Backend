import { formatWhen } from "@/lib/format";

import { ROLE_LABELS, type SessionUser } from "../types";
import { ChangePasswordForm } from "./change-password-form";

const card =
  "rounded-2xl border border-border bg-card p-6";

/** «Mi cuenta»: datos de la sesión y cambio de contraseña. */
export function AccountView({ user }: { user: SessionUser }) {
  const rows: [string, string][] = [
    ["Nombre", `${user.nombre} ${user.apellido}`],
    ["Correo electrónico", user.email],
    ["Rol", ROLE_LABELS[user.rol ?? ""] ?? user.rol ?? "Sin rol"],
    ["Último acceso", formatWhen(user.ultimo_acceso)],
  ];

  return (
    <div className="flex flex-wrap items-start gap-6">
      <section className={`${card} flex min-w-0 flex-[1_1_420px] flex-col`}>
        <h2 className="mb-1 font-heading text-lg font-semibold">Cambiar contraseña</h2>
        <p className="mb-5 max-w-[520px] text-sm leading-normal text-muted-foreground">
          Al cambiarla se cierran las demás sesiones abiertas con la contraseña anterior. Esta sesión sigue
          activa. El cambio queda registrado en la auditoría.
        </p>
        <ChangePasswordForm />
      </section>

      <aside className="min-w-[280px] flex-[0_1_340px] rounded-2xl bg-navy-900 p-6 text-white">
        <div className="mb-4 text-[13px] font-semibold text-on-navy-dim">Tu cuenta</div>
        <dl className="flex flex-col gap-3">
          {rows.map(([key, value]) => (
            <div key={key} className="flex justify-between gap-3 border-b border-white/[.12] pb-3 text-sm">
              <dt className="text-on-navy-muted">{key}</dt>
              <dd className="min-w-0 text-right font-bold break-words">{value}</dd>
            </div>
          ))}
        </dl>
      </aside>
    </div>
  );
}
