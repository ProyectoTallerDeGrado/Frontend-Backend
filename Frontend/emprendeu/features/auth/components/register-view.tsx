import { AuthShell } from "./auth-shell";
import { RegisterForm } from "./register-form";

export function RegisterView() {
  return (
    <AuthShell
      title="Solicitar acceso"
      subtitle="Registra tu cuenta institucional para usar el panel."
    >
      <RegisterForm />
    </AuthShell>
  );
}
