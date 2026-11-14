import Image from "next/image";
import Link from "next/link";

export function SiteFooter({ signedIn }: { signedIn: boolean }) {
  return (
    <footer className="border-t border-white/10 bg-navy-950 text-on-navy-faint">
      <div className="mx-auto flex max-w-[1240px] flex-wrap items-center justify-between gap-6 px-5 py-10 text-sm sm:px-8">
        <div className="flex items-center gap-3">
          <Image src="/brand/cie-u-logo.png" alt="" width={36} height={36} className="size-9 rounded-[9px] object-cover ring-1 ring-white/20" />
          <div>
            <div className="font-semibold text-white">Centro de Innovación y Emprendimiento Universitario</div>
            <div>FCEE · UAGRM · Santa Cruz, Bolivia</div>
          </div>
        </div>
        <nav aria-label="Enlaces" className="flex flex-wrap gap-x-6 gap-y-2">
          <Link href="/apply" className="font-semibold text-white hover:underline">
            Postular
          </Link>
          <Link href={signedIn ? "/panel" : "/login"} className="hover:text-white hover:underline">
            {signedIn ? "Ir al panel" : "Ingreso del personal"}
          </Link>
        </nav>
      </div>
    </footer>
  );
}
