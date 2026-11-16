import { AuthShell } from "./auth-shell";
import { SuccessNotice } from "./form-notice";
import { ResetPasswordForm } from "./reset-password-form";

export function ResetPasswordView({ email, sent = false }: { email: string; sent?: boolean }) {
  return (
    <AuthShell title="Nueva contraseña" subtitle="Escribe el código que te llegó al correo y elige tu contraseña nueva.">
      {sent && <SuccessNotice>Si el correo está registrado, te enviamos un código de 6 dígitos.</SuccessNotice>}
      <ResetPasswordForm email={email} />
    </AuthShell>
  );
}
