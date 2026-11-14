import { Download } from "lucide-react";

import { NoAccess } from "@/components/layout/no-access";
import { SectionHeader } from "@/components/layout/section-header";
import { hasPermission, requireSession } from "@/features/auth";
import { formatDateTime } from "@/lib/format";

import { listVentureDocuments } from "../server/queries";
import { DeleteDocumentButton } from "./delete-document-button";
import { UploadDocumentSheet } from "./upload-document-sheet";

/** CU30 · Documentos de un emprendimiento: subir, descargar y eliminar. */
export async function DocumentsScreen({ ventureId }: { ventureId: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "emprendedores:consulta")) return <NoAccess section="Documentos" />;

  const docs = await listVentureDocuments(ventureId);
  const canUpload = hasPermission(user, "emprendedores:registro");
  const canDelete = hasPermission(user, "emprendedores:modificacion");

  return (
    <>
      <SectionHeader
        title="Documentos"
        subtitle="Archivos del emprendimiento, incluida la evidencia de sus hitos."
        actions={canUpload ? <UploadDocumentSheet ventureId={ventureId} /> : undefined}
      />
      <div className="relative overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[640px] border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-surface-head text-[13px] font-semibold text-muted-foreground">
              <th scope="col" className="px-5 py-3.5">Archivo</th>
              <th scope="col" className="px-5 py-3.5">Origen</th>
              <th scope="col" className="px-5 py-3.5">Subido</th>
              <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>
            </tr>
          </thead>
          <tbody>
            {docs.length === 0 && (
              <tr>
                <td colSpan={4} className="px-5 py-10 text-center text-muted-foreground">
                  Este emprendimiento aún no tiene documentos.
                </td>
              </tr>
            )}
            {docs.map((d) => (
              <tr key={d.documento_id} className="border-t border-muted transition-colors hover:bg-row-hover">
                <td className="px-5 py-3.5 font-semibold">{d.nombre}</td>
                <td className="px-5 py-3.5 text-muted-foreground">{d.hito_id ? "Evidencia de hito" : "Documento general"}</td>
                <td className="px-5 py-3.5 text-muted-foreground">{formatDateTime(d.fecha_subida)}</td>
                <td className="px-5 py-3 text-right">
                  <div className="flex justify-end gap-2">
                    <a
                      href={`/ventures/${ventureId}/documents/${d.documento_id}/download`}
                      aria-label={`Descargar ${d.nombre}`}
                      className="inline-flex size-11 items-center justify-center rounded-xl border border-border-strong outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
                    >
                      <Download aria-hidden="true" className="size-4" />
                    </a>
                    {canDelete && <DeleteDocumentButton ventureId={ventureId} documentId={d.documento_id} name={d.nombre} />}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
