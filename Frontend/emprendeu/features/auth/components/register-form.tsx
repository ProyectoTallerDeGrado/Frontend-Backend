"use client";

import { useActionState } from "react";
import Link from "next/link";
import { ArrowRight, LoaderCircle } from "lucide-react";

import { Button } from "@/components/ui/button";

import { registerAction } from "../server/actions";
import type { FormState } from "../types";
import { AuthField } from "./auth-field";
import { ErrorNotice, SecurityNotice } from "./form-notice";

const initialState: FormState = {};

export function RegisterForm() {
  const [state, formAction, pending] = useActionState(registerAction, initialState);
  const errors = state.errors ?? {};

  return (
    <>
      <form action={formAction} noValidate className="flex flex-col gap-5">
        <AuthField
          name="name"
          label="Nombre completo"
          placeholder="Nombre y apellidos"
          autoComplete="name"
          defaultValue={state.values?.name}
          error={errors.name}
        />
        <AuthField
          name="email"
          label="Correo electrónico"
          type="email"
          placeholder="nombre@uagrm.edu.bo"
          autoComplete="email"
          defaultValue={state.values?.email}
          error={errors.email}
        />
        <AuthField
          name="password"
          label="Contraseña"
          type="password"
          placeholder="Mínimo 8 caracteres"
          autoComplete="new-password"
          error={errors.password}
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
          {pending ? "Creando cuenta…" : "Crear cuenta"}
          {pending ? (
            <LoaderCircle aria-hidden="true" className="size-5 animate-spin" />
          ) : (
            <ArrowRight aria-hidden="true" className="size-5" />
          )}
        </Button>
        <Link
          href="/login"
          className="inline-flex min-h-11 items-center self-center text-[15px] font-semibold text-primary hover:text-[#123aa8]"
        >
          ¿Ya tienes cuenta? Inicia sesión
        </Link>
      </form>
      <SecurityNotice>
        La cuenta se crea sin acceso al panel. Un administrador debe asignarte un
        rol antes de que puedas ingresar.
      </SecurityNotice>
    </>
  );
}
