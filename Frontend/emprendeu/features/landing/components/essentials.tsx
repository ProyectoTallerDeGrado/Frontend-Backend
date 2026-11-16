import { ESSENTIALS } from "../content";
import { Container, SectionHeading, SectionLead } from "./primitives";

/**
 * «Lo esencial»: lo práctico que un estudiante pregunta antes de postular, en una lista de
 * definiciones (término y detalle), sin tarjetas. Solo datos confirmados por el CIE-U.
 */
export function Essentials() {
  return (
    <section id="esencial" aria-labelledby="esencial-title" className="scroll-mt-20 bg-card py-24 sm:py-28">
      <Container>
        <SectionHeading id="esencial-title" size="md">
          Lo que necesitas saber.
        </SectionHeading>
        <SectionLead>Antes de postular, lo práctico.</SectionLead>
        <dl className="mt-12 grid gap-x-10 gap-y-9 sm:grid-cols-2 lg:grid-cols-3">
          {ESSENTIALS.map((e) => (
            <div key={e.term} className="border-t-2 border-navy-950 pt-4">
              <dt className="font-heading text-xl font-bold tracking-[-.01em]">{e.term}</dt>
              <dd className="mt-2 max-w-[38ch] text-[16px] leading-relaxed text-muted-foreground">{e.detail}</dd>
            </div>
          ))}
        </dl>
      </Container>
    </section>
  );
}
