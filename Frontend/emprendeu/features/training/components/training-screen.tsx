import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { Pagination } from "@/components/layout/pagination";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { TRAINING_PAGE_SIZE, listTrainings } from "../server/queries";
import { EditTrainingSheet, NewTrainingSheet } from "./training-form-sheet";
import { TrainingStateButtons } from "./training-state-buttons";

const TABS = [
  { value: "", label: "Todas" },
  { value: "borrador", label: "Borradores" },
  { value: "publicada", label: "Publicadas" },
  { value: "realizada", label: "Realizadas" },
  { value: "cancelada", label: "Canceladas" },
] as const;

const TONE: Record<string, string> = {
  borrador: "bg-muted text-muted-foreground",
  publicada: "bg-success-tint text-success-foreground",
  realizada: "bg-blue-50 text-primary",
  cancelada: "bg-[#ffe3e8] text-[#8f0f25]",
};

function href(estado: string, page?: number): string {
  const search = new URLSearchParams();
  if (estado) search.set("estado", estado);
  if (page && page > 1) search.set("page", String(page));
  const query = search.toString();
  return query ? `/training?${query}` : "/training";
}

/** CU27 · Capacitaciones: la coordinación crea, edita y publica; el asesor consulta. */
export async function TrainingScreen({ estado, page }: { estado: string; page: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "asesorias:consulta")) return <NoAccess section="Capacitaciones" />;
  const canManage = user.rol !== "asesor" && hasPermission(user, "asesorias:registro");
  const current = TABS.some((t) => t.value === estado) ? estado : "";
  const result = await listTrainings({ estado: current, page });

  return (
    <>
      <PageHeader
        title="Capacitaciones"
        subtitle="Talleres y charlas del programa. Un borrador no lo ve nadie más; al publicarlo, los emprendedores lo ven en la app."
        actions={canManage ? <NewTrainingSheet /> : undefined}
      />
      <nav aria-label="Estado" className="mb-5 flex flex-wrap gap-2">
        {TABS.map((t) => (
          <Link
            key={t.value}
            href={href(t.value)}
            aria-current={t.value === current ? "page" : undefined}
            className={`inline-flex min-h-11 items-center rounded-xl px-4 text-sm font-semibold ${
              t.value === current ? "bg-primary text-primary-foreground" : "border-[1.5px] border-border-strong bg-card hover:bg-blue-50"
            }`}
          >
            {t.label}
          </Link>
        ))}
      </nav>
      <div className="overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[900px] border-collapse text-left text-sm">
          <thead>
            <tr className="bg-[#f4f6fb] text-[12px] font-bold tracking-[.06em] text-muted-foreground uppercase">
              <th scope="col" className="px-5 py-3.5">Capacitación</th>
              <th scope="col" className="px-5 py-3.5">Fecha</th>
              <th scope="col" className="px-5 py-3.5">Modalidad</th>
              <th scope="col" className="px-5 py-3.5">Estado</th>
              <th scope="col" className="px-5 py-3.5">Inscritos</th>
              <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>
            </tr>
          </thead>
          <tbody>
            {result.items.length === 0 && (
              <tr>
                <td colSpan={6} className="px-5 py-10 text-center text-muted-foreground">
                  No hay capacitaciones con ese filtro.
                </td>
              </tr>
            )}
            {result.items.map((t) => {
              const open = t.estado === "publicada" || t.estado === "realizada";
              return (
                <tr key={t.capacitacion_id} className="border-t border-[#eef2fa] align-middle">
                  <td className="px-5 py-3.5">
                    <div className="font-semibold">{t.titulo}</div>
                    {t.tipo && <div className="text-[13px] text-muted-foreground">{t.tipo}</div>}
                  </td>
                  <td className="px-5 py-3.5 text-muted-foreground">{t.fecha ? formatDateTime(t.fecha) : "Sin fecha"}</td>
                  <td className="px-5 py-3.5 capitalize text-muted-foreground">{t.modalidad ?? "—"}</td>
                  <td className="px-5 py-3.5">
                    <span className={`rounded-full px-3 py-1 text-[13px] font-bold capitalize ${TONE[t.estado ?? ""] ?? "bg-muted"}`}>
                      {t.estado ?? "—"}
                    </span>
                  </td>
                  <td className="px-5 py-3.5">{t.total_inscritos}</td>
                  <td className="px-5 py-3 text-right">
                    <div className="flex flex-wrap justify-end gap-2">
                      {open && (
                        <Link
                          href={`/training/${t.capacitacion_id}/participants`}
                          className="inline-flex min-h-11 items-center px-2 text-sm font-semibold text-primary hover:underline"
                        >
                          Participantes
                        </Link>
                      )}
                      {canManage && (t.estado === "borrador" || t.estado === "publicada") && <EditTrainingSheet training={t} />}
                      {canManage && <TrainingStateButtons id={t.capacitacion_id} title={t.titulo} estado={t.estado} />}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <Pagination page={result.page} pageSize={TRAINING_PAGE_SIZE} total={result.total} hrefFor={(p) => href(current, p)} />
    </>
  );
}
