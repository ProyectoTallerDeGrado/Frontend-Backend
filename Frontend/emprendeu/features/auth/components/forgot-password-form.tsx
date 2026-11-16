"use client";

import { useActionState } from "react";
import Link from "next/link";
import { ArrowRight, LoaderCircle } from "lucide-react";

import { Button } from "@/components/ui/button";

import { forgotPasswordAction } from "../server/actions";
import type { FormState } from "../types";
import { AuthField } from "./auth-field";
import { ErrorNotice, SecurityNotice } from "./form-notice";

const initialState: FormState = {};

export function ForgotPasswordForm() {
  const [state, formAction, pending] = useActionState(forgotPasswordAction, initialState);
  const errors = state.errors ?? {};
  return (
    <>
      <form action={formAction} noValidate className="flex flex-col gap-5">
        <AuthField
          name="email"
          label="Correo electrónico"
          type="email"
          placeholder="nombre@uagrm.edu.bo"
          autoComplete="email"
          defaultValue={state.values?.email}
          error={errors.email}
        />
        {state.message && <ErrorNotice message={state.message} />}
        <Button
          type="submit"
          disabled={pending}
          className="h-13 w-full gap-2.5 rounded-xl text-base font-bold hover:-translate-y-0.5 hover:shadow-cta"
        >
          {pending ? "Enviando…" : "Enviar código"}
          {pending ? (
            <LoaderCircle aria-hidden="true" className="size-5 animate-spin" />
          ) : (
            <ArrowRight aria-hidden="true" className="size-5" />
          )}
        </Button>
        <Link
          href="/login"
          className="inline-flex min-h-11 items-center self-center text-[15px] font-semibold text-primary hover:text-primary-hover"
        >
          Volver al ingreso
        </Link>
      </form>
      <SecurityNotice>
        Te enviaremos un código de 6 dígitos que vence en 15 minutos. Por seguridad, la respuesta es la
        misma aunque el correo no esté registrado.
      </SecurityNotice>
    </>
  );
}
