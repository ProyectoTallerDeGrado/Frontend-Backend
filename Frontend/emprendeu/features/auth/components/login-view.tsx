import { AuthShell } from "./auth-shell";
import { SuccessNotice } from "./form-notice";
import { LoginForm } from "./login-form";

type LoginViewProps = {
  /** Llegó desde el registro: se avisa que la cuenta ya existe. */
  registered?: boolean;
};

export function LoginView({ registered = false }: LoginViewProps) {
  return (
    <AuthShell
      title="Acceso administrativo"
      subtitle="Ingresa con tu cuenta institucional para continuar."
    >
      {registered && (
        <SuccessNotice>
          Cuenta creada. Cuando un administrador te asigne un rol podrás ingresar.
        </SuccessNotice>
      )}
      <LoginForm />
    </AuthShell>
  );
}
