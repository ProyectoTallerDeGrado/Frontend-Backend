import { BellRing, CalendarDays, ChartColumn } from "lucide-react";

const POINTS = [
  { icon: BellRing, text: "Si te frenas, salta una alerta y alguien te busca." },
  { icon: CalendarDays, text: "Tu asesor ve tus sesiones, avances y compromisos." },
  { icon: ChartColumn, text: "La coordinación decide contigo cuándo pasas de etapa." },
];

/** «Y detrás, el CIE-U»: el seguimiento del personal, contado desde el lado del estudiante. */
export function StaffStrip() {
  return (
    <section aria-labelledby="detras-title" className="bg-blue-50 py-20">
      <div className="mx-auto grid max-w-[1240px] gap-10 px-5 sm:px-8 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
        <div>
          <h2 id="detras-title" className="font-heading text-[clamp(30px,3.6vw,46px)] leading-[1.05] font-bold tracking-[-.03em] text-balance text-navy-950">
            Y detrás de la app, personas.
          </h2>
          <p className="mt-4 max-w-[46ch] text-lg leading-relaxed text-info-foreground">
            Asesores y coordinación siguen tu avance desde el panel del CIE-U. No es para vigilarte: es para que
            nadie se quede atrás.
          </p>
        </div>
        <ul className="grid gap-3 sm:grid-cols-3 lg:grid-cols-1">
          {POINTS.map(({ icon: Icon, text }) => (
            <li key={text} className="flex items-center gap-4 rounded-2xl bg-card px-5 py-4 text-[16px] font-semibold text-navy-950">
              <span className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-primary text-white">
                <Icon aria-hidden="true" className="size-5" />
              </span>
              {text}
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
