import { ApplyForm } from "./apply-form";

/** CU26 · Página pública de postulación al programa de acompañamiento del CIE-U. */
export function ApplyView() {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-[640px] flex-col justify-center px-6 py-12">
      <h1 className="mb-2 font-heading text-[28px] font-bold tracking-[-.01em] text-foreground">Postula tu emprendimiento</h1>
      <p className="mb-8 text-base leading-normal text-muted-foreground">
        Completa el formulario para entrar al programa de acompañamiento del CIE-U. Evaluaremos tu postulación y te
        contactaremos con el resultado.
      </p>
      <ApplyForm />
    </main>
  );
}
