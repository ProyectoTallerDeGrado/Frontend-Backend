import { AuthShell } from "./auth-shell";
import { ForgotPasswordForm } from "./forgot-password-form";

export function ForgotPasswordView() {
  return (
    <AuthShell title="Recuperar contraseña" subtitle="Escribe tu correo y te enviaremos un código para crear una nueva.">
      <ForgotPasswordForm />
    </AuthShell>
  );
}
