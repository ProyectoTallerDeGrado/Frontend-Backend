"use client";

import { useActionState, useEffect, useRef } from "react";
import { LoaderCircle } from "lucide-react";

import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";

import { changePasswordAction } from "../server/actions";
import type { FormState } from "../types";
import { AuthField } from "./auth-field";
import { ErrorNotice, SuccessNotice } from "./form-notice";

const initialState: FormState = {};

export function ChangePasswordForm() {
  const [state, formAction, pending] = useActionState(changePasswordAction, initialState);
  const formRef = useRef<HTMLFormElement>(null);
  const errors = state.errors ?? {};

  // Tras un cambio correcto se vacían los campos (las contraseñas no deben quedar en pantalla).
  useEffect(() => {
    if (state.success) {
      formRef.current?.reset();
      toast.success("Contraseña actualizada.");
    }
  }, [state]);

  return (
    <form ref={formRef} action={formAction} noValidate className="flex max-w-[460px] flex-col gap-5">
      {state.success && state.message && <SuccessNotice>{state.message}</SuccessNotice>}
      <AuthField
        name="currentPassword"
        label="Contraseña actual"
        type="password"
        autoComplete="current-password"
        error={errors.currentPassword}
      />
      <AuthField
        name="newPassword"
        label="Contraseña nueva"
        type="password"
        autoComplete="new-password"
        error={errors.newPassword}
      />
      <AuthField
        name="confirmPassword"
        label="Repite la contraseña nueva"
        type="password"
        autoComplete="new-password"
        error={errors.confirmPassword}
      />
      {!state.success && state.message && <ErrorNotice message={state.message} />}
      <Button
        type="submit"
        disabled={pending}
        className="h-[52px] w-full gap-2.5 rounded-xl text-base font-bold sm:w-auto sm:self-start sm:px-8"
      >
        {pending && <LoaderCircle aria-hidden="true" className="size-5 animate-spin" />}
        {pending ? "Guardando…" : "Cambiar contraseña"}
      </Button>
    </form>
  );
}
