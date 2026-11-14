import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { getAiStatus, getKnowledgeGaps, listKnowledge } from "../server/queries";
import { DeactivateKnowledgeButton } from "./deactivate-knowledge-button";
import { KnowledgeGapsSection } from "./knowledge-gaps";
import { UploadKnowledgeSheet } from "./upload-knowledge-sheet";

const STATES: Record<string, { label: string; tone: string }> = {
  activo: { label: "Activo", tone: "bg-success-tint text-success-foreground" },
  procesando: { label: "Procesando", tone: "bg-blue-50 text-primary" },
  error: { label: "Error", tone: "bg-danger-tint text-danger-foreground" },
  inactivo: { label: "Inactivo", tone: "bg-muted text-muted-foreground" },
};

/** CU31 · Base de conocimiento del coach: subir documentos y ver su estado de procesamiento. */
export async function KnowledgeScreen() {
  const user = await requireSession();
  if (!hasPermission(user, "config:consulta")) return <NoAccess section="Base de conocimiento" />;
  const [documents, status, gaps] = await Promise.all([listKnowledge(), getAiStatus(), getKnowledgeGaps()]);
  const canManage = hasPermission(user, "config:modificacion");

  return (
    <>
      <PageHeader
        title="Base de conocimiento"
        subtitle="Documentos con los que responde el coach IA. Solo los activos se usan en las respuestas."
        actions={canManage ? <UploadKnowledgeSheet /> : undefined}
      />

      <div className="mb-6 grid gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-border bg-card px-5 py-4">
          <div className="text-[13px] font-semibold text-muted-foreground">Servicio de IA (Ollama)</div>
          <div
            className={`mt-1 font-heading text-xl font-semibold ${status.ollama_disponible ? "text-success-foreground" : "text-danger-foreground"}`}
          >
            {status.ollama_disponible ? "Disponible" : "No responde"}
          </div>
          {!status.ollama_disponible && (
            <p className="mt-1 text-[13px] text-muted-foreground">
              Sin el servicio, el coach no responde y los documentos nuevos quedan en estado «Error».
            </p>
          )}
        </div>
        <div className="rounded-2xl border border-border bg-card px-5 py-4">
          <div className="text-[13px] font-semibold text-muted-foreground">Documentos activos</div>
          <div className="mt-1 font-heading text-xl font-semibold">{status.documentos_activos}</div>
        </div>
      </div>

      <div className="relative overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[820px] border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
              <th scope="col" className="px-5 py-3.5">Documento</th>
              <th scope="col" className="px-5 py-3.5">Estado</th>
              <th scope="col" className="px-5 py-3.5">Fragmentos</th>
              <th scope="col" className="px-5 py-3.5">Cargado</th>
              {canManage && <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>}
            </tr>
          </thead>
          <tbody>
            {documents.length === 0 && (
              <tr>
                <td colSpan={canManage ? 5 : 4} className="px-5 py-10 text-center text-muted-foreground">
                  Todavía no hay documentos. Sube el primero para que el coach pueda responder con la información del CIE-U.
                </td>
              </tr>
            )}
            {documents.map((d) => {
              const state = STATES[d.estado ?? ""] ?? { label: d.estado ?? "—", tone: "bg-muted text-muted-foreground" };
              return (
                <tr key={d.documento_conocimiento_id} className="border-t border-muted transition-colors hover:bg-row-hover align-middle">
                  <td className="px-5 py-3.5">
                    <div className="font-semibold">{d.titulo}</div>
                    {d.fuente && <div className="text-[13px] text-muted-foreground">{d.fuente}</div>}
                  </td>
                  <td className="px-5 py-3.5">
                    <span className={`rounded-full px-3 py-1 text-[13px] font-bold ${state.tone}`}>{state.label}</span>
                  </td>
                  <td className="px-5 py-3.5">{d.total_fragmentos}</td>
                  <td className="px-5 py-3.5 text-muted-foreground">{d.fecha_carga ? formatDateTime(d.fecha_carga) : "—"}</td>
                  {canManage && (
                    <td className="px-5 py-3 text-right">
                      {d.estado !== "inactivo" && (
                        <DeactivateKnowledgeButton id={d.documento_conocimiento_id} title={d.titulo} />
                      )}
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <KnowledgeGapsSection gaps={gaps} />
    </>
  );
}
