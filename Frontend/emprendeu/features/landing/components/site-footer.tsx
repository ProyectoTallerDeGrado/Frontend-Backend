import Image from "next/image";
import Link from "next/link";

import { CTA, NAV_LINKS } from "../content";
import { Container } from "./primitives";

export function SiteFooter({ signedIn }: { signedIn: boolean }) {
  return (
    <footer className="border-t border-white/10 bg-navy-950 pb-20 text-on-navy-faint sm:pb-0">
      <Container className="flex flex-wrap items-start justify-between gap-8 py-10 text-sm">
        <div className="flex items-center gap-3">
          <Image src="/brand/cie-u-logo.png" alt="" width={36} height={36} className="size-9 rounded-lg object-cover ring-1 ring-white/20" />
          <div>
            <div className="font-semibold text-white">Centro de Innovación y Emprendimiento Universitario</div>
            <div>FCEE, UAGRM. Santa Cruz, Bolivia</div>
          </div>
        </div>
        <nav aria-label="Pie de página" className="flex flex-wrap gap-x-6 gap-y-3">
          {NAV_LINKS.map((l) => (
            <a key={l.href} href={l.href} className="hover:text-white hover:underline">
              {l.label}
            </a>
          ))}
          <Link href="/apply" className="font-semibold text-white hover:underline">
            {CTA.applyShort}
          </Link>
          <Link href={signedIn ? "/panel" : "/login"} className="hover:text-white hover:underline">
            {signedIn ? CTA.panel : CTA.staff}
          </Link>
        </nav>
      </Container>
    </footer>
  );
}
