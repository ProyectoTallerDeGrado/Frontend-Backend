"use client";

import { useActionState } from "react";
import Link from "next/link";
import { ArrowRight, LoaderCircle } from "lucide-react";

import { Button } from "@/components/ui/button";

import { resetPasswordAction } from "../server/actions";
import type { FormState } from "../types";
import { AuthField } from "./auth-field";
import { ErrorNotice } from "./form-notice";

const initialState: FormState = {};

export function ResetPasswordForm({ email }: { email: string }) {
  const [state, formAction, pending] = useActionState(resetPasswordAction, initialState);
  const errors = state.errors ?? {};
  return (
    <form action={formAction} noValidate className="flex flex-col gap-5">
      <AuthField
        name="email"
        label="Correo electrónico"
        type="email"
        autoComplete="email"
        defaultValue={state.values?.email ?? email}
        error={errors.email}
      />
      <AuthField
        name="code"
        label="Código de 6 dígitos"
        placeholder="123456"
        autoComplete="one-time-code"
        defaultValue={state.values?.code}
        error={errors.code}
      />
      <AuthField
        name="newPassword"
        label="Contraseña nueva"
        type="password"
        placeholder="Mínimo 8 caracteres"
        autoComplete="new-password"
        error={errors.newPassword}
      />
      <AuthField
        name="confirmPassword"
        label="Confirmar contraseña"
        type="password"
        placeholder="Repite tu contraseña"
        autoComplete="new-password"
        error={errors.confirmPassword}
      />
      {state.message && <ErrorNotice message={state.message} />}
      <Button
        type="submit"
        disabled={pending}
        className="h-[54px] w-full gap-2.5 rounded-xl text-base font-bold hover:-translate-y-0.5 hover:shadow-[0_12px_24px_-10px_rgba(31,79,214,.7)]"
      >
        {pending ? "Guardando…" : "Restablecer contraseña"}
        {pending ? (
          <LoaderCircle aria-hidden="true" className="size-5 animate-spin" />
        ) : (
          <ArrowRight aria-hidden="true" className="size-5" />
        )}
      </Button>
      <Link
        href="/forgot-password"
        className="inline-flex min-h-11 items-center self-center text-[15px] font-semibold text-primary hover:text-primary-hover"
      >
        Pedir un código nuevo
      </Link>
    </form>
  );
}
