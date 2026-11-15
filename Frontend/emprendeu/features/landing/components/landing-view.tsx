import { AppShowcase } from "./app-showcase";
import { ApplySteps } from "./apply-steps";
import { ClosingCta } from "./closing-cta";
import { Essentials } from "./essentials";
import { Faq } from "./faq";
import { Hero } from "./hero";
import { JourneySection } from "./journey-section";
import { MotionToggle } from "./motion-toggle";
import { ProblemSolution } from "./problem-solution";
import { SiteFooter } from "./site-footer";
import { SiteHeader } from "./site-header";
import { StaffStrip } from "./staff-strip";

/**
 * Landing pública del CIE-U, contada como historia: gancho → el problema y el giro (el único momento
 * grande) → el camino → qué contiene la app → quién está detrás → lo esencial → cómo postular → dudas → cierre.
 */
export function LandingView({ signedIn }: { signedIn: boolean }) {
  return (
    <div className="landing flex min-h-screen flex-col bg-background">
      {/* Sin JavaScript no hay animaciones: el contenido debe verse igual. */}
      <noscript>
        <style>{`[data-anim="pending"] [data-reveal]{opacity:1 !important}`}</style>
      </noscript>
      <a
        href="#contenido"
        className="sr-only rounded-xl bg-white px-4 py-3 font-semibold text-navy-950 focus:not-sr-only focus:fixed focus:top-3 focus:left-3 focus:z-[60]"
      >
        Saltar al contenido
      </a>
      <SiteHeader signedIn={signedIn} />
      <main id="contenido" tabIndex={-1} className="outline-none">
        <Hero />
        <ProblemSolution />
        <JourneySection />
        <AppShowcase />
        <StaffStrip />
        <Essentials />
        <ApplySteps />
        <Faq />
        <ClosingCta />
      </main>
      <SiteFooter signedIn={signedIn} />
      <MotionToggle />
    </div>
  );
}
