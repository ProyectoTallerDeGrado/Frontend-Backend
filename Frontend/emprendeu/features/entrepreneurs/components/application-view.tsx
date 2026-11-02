import { ApplicationForm } from "./application-form";

/** Página pública `/postular`: presenta el programa y muestra el formulario. */
export function ApplicationView() {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-[640px] flex-col justify-center px-5 py-12">
      <p className="mb-2 text-[13px] font-bold tracking-[.08em] text-primary uppercase">CIE-U · Programa de emprendimiento</p>
      <h1 className="mb-3 font-heading text-[32px] leading-tight font-bold tracking-[-.01em]">Postúlate al programa</h1>
      <p className="mb-8 text-base leading-normal text-muted-foreground">
        Cuéntanos quién eres y qué quieres emprender. La coordinación revisa cada postulación y, si te admiten, te
        entrega tu acceso a la app para seguir tu camino, agendar mentorías y conversar con el coach.
      </p>
      <ApplicationForm />
    </main>
  );
}
