"use client";

import { useActionState } from "react";
import Link from "next/link";
import { ArrowRight, LoaderCircle } from "lucide-react";

import { Button } from "@/components/ui/button";

import { loginAction } from "../server/actions";
import type { FormState } from "../types";
import { AuthField } from "./auth-field";
import { ErrorNotice, SecurityNotice } from "./form-notice";

const initialState: FormState = {};

export function LoginForm() {
  const [state, formAction, pending] = useActionState(loginAction, initialState);
  const errors = state.errors ?? {};

  return (
    <>
      <form action={formAction} noValidate className="flex flex-col gap-5">
        <AuthField
          name="email"
          label="Correo electrónico"
          type="email"
          placeholder="admin@uagrm.edu.bo"
          autoComplete="username"
          defaultValue={state.values?.email}
          error={errors.email}
        />
        <AuthField
          name="password"
          label="Contraseña"
          type="password"
          placeholder="••••••••••"
          autoComplete="current-password"
          error={errors.password}
        />
        {state.message && <ErrorNotice message={state.message} />}
        <Button
          type="submit"
          disabled={pending}
          className="h-13 w-full gap-2.5 rounded-xl text-base font-bold hover:-translate-y-0.5 hover:shadow-cta"
        >
          {pending ? "Ingresando…" : "Ingresar al panel"}
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
          ¿Olvidaste tu contraseña?
        </Link>
        <Link
          href="/apply"
          className="inline-flex min-h-11 items-center self-center text-[15px] font-semibold text-primary hover:text-primary-hover"
        >
          Solicitar una cuenta
        </Link>
      </form>
      <SecurityNotice>
        Acceso protegido por autenticación. Las acciones sensibles quedan
        registradas para auditoría.
      </SecurityNotice>
    </>
  );
}
