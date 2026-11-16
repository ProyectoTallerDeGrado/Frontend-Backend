import { BrandPanel } from "@/features/auth";
import { APPLY_STEPS } from "@/features/landing";

import { ApplyForm } from "./apply-form";

/**
 * CU26 · Página pública de postulación al programa de acompañamiento del CIE-U. Sigue a la
 * landing: mismo panel de marca, con lo que pasa después de enviar (los pasos de «Cómo postular»).
 */
export function ApplyView() {
  return (
    <div className="flex min-h-screen flex-wrap">
      <BrandPanel
        compact
        back={{ href: "/", label: "Volver al inicio" }}
        badge="Gratis para estudiantes de la UAGRM"
        title="Postula tu emprendimiento."
        text="Te toma unos minutos. No necesitas un plan terminado: si tu idea está verde, la preincubación existe para validarla."
      >
        <ol className="mt-8 hidden flex-col gap-4 lg:flex">
          {APPLY_STEPS.map((step, i) => (
            <li key={step.title} className="flex gap-4">
              <span
                aria-hidden="true"
                className="flex size-9 shrink-0 items-center justify-center rounded-full bg-white/10 font-heading text-sm font-bold ring-1 ring-white/20"
              >
                {i + 1}
              </span>
              <div>
                <p className="font-semibold">{step.title}</p>
                <p className="mt-0.5 max-w-[44ch] text-[15px] leading-relaxed text-on-navy-muted">{step.text}</p>
              </div>
            </li>
          ))}
        </ol>
      </BrandPanel>
      <main className="flex min-w-0 flex-[1_1_480px] justify-center px-6 py-10 sm:px-8 sm:py-14">
        <div className="w-full max-w-[560px]">
          <h2 className="mb-2 font-heading text-[28px] font-bold tracking-[-.01em] text-foreground">Cuéntanos de ti y de tu idea</h2>
          <p className="mb-8 text-base leading-normal text-muted-foreground">
            El equipo del CIE-U lee cada postulación y te responde por correo.
          </p>
          <ApplyForm />
        </div>
      </main>
    </div>
  );
}
