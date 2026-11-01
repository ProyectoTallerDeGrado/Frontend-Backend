import { Lock } from "lucide-react";

export function NoAccess({ section }: { section: string }) {
  return (
    <div className="mx-auto mt-16 flex max-w-md flex-col items-center gap-3 rounded-2xl border border-border bg-card p-10 text-center">
      <Lock aria-hidden="true" className="size-8 text-muted-foreground" />
      <h1 className="font-heading text-xl font-bold">Sin acceso a {section}</h1>
      <p className="text-[15px] leading-normal text-muted-foreground">
        Tu rol no tiene permiso para ver esta sección. Si lo necesitas, pídeselo a un administrador.
      </p>
    </div>
  );
}
