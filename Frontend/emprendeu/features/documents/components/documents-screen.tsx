import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { listVentureOptions } from "@/features/ventures";
import { formatDateTime } from "@/lib/format";

import { listDocuments } from "../server/queries";
import { DeleteDocumentButton } from "./delete-document-button";
import { UploadDocumentSheet } from "./upload-document-sheet";

/** CU30 · Documentos de los emprendimientos: subir, descargar y eliminar (coordinación y asesor). */
export async function DocumentsScreen({ ventureId }: { ventureId: number | null }) {
  const user = await requireSession();
  if (!hasPermission(user, "emprendedores:consulta")) return <NoAccess section="Documentos" />;
  const [documents, ventures] = await Promise.all([listDocuments(ventureId ?? undefined), listVentureOptions()]);
  const names = new Map(ventures.map((v) => [v.id, v.name]));
  // Coordinación sube y elimina siempre; un asesor, solo en los emprendimientos asignados (lo valida el backend).
  const canWrite = hasPermission(user, "emprendedores:registro") || user.rol === "asesor";

  return (
    <>
      <PageHeader
        title="Documentos"
        subtitle="Archivos de cada emprendimiento. El emprendedor solo ve los de su emprendimiento."
        actions={canWrite ? <UploadDocumentSheet ventures={ventures} defaultVenture={ventureId ? String(ventureId) : ""} /> : undefined}
      />
      <form method="get" action="/documents" className="mb-5 flex flex-wrap items-end gap-3">
        <label className="flex min-w-[240px] flex-[1_1_320px] flex-col gap-1.5 text-[13px] font-semibold">
          Emprendimiento
          <select
            name="emprendimiento_id"
            defaultValue={ventureId ?? ""}
            className="h-12 rounded-xl border-[1.5px] border-border-strong bg-card px-4 text-[15px] font-normal outline-none focus-visible:border-primary focus-visible:ring-4 focus-visible:ring-primary/15"
          >
            <option value="">Todos</option>
            {ventures.map((v) => (
              <option key={v.id} value={v.id}>
                {v.name}
              </option>
            ))}
          </select>
        </label>
        <button
          type="submit"
          className="h-12 rounded-xl border-[1.5px] border-border-strong bg-card px-5 text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
        >
          Filtrar
        </button>
      </form>
      <div className="overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[760px] border-collapse text-left text-sm">
          <thead>
            <tr className="bg-[#f4f6fb] text-[12px] font-bold tracking-[.06em] text-muted-foreground uppercase">
              <th scope="col" className="px-5 py-3.5">Documento</th>
              <th scope="col" className="px-5 py-3.5">Emprendimiento</th>
              <th scope="col" className="px-5 py-3.5">Subido</th>
              <th scope="col" className="px-5 py-3.5"><span className="sr-only">Acciones</span></th>
            </tr>
          </thead>
          <tbody>
            {documents.length === 0 && (
              <tr>
                <td colSpan={4} className="px-5 py-10 text-center text-muted-foreground">
                  No hay documentos con ese filtro.
                </td>
              </tr>
            )}
            {documents.map((d) => (
              <tr key={d.documento_id} className="border-t border-[#eef2fa] align-middle">
                <td className="px-5 py-3.5">
                  <div className="font-semibold">{d.nombre}</div>
                  {d.hito_id && <div className="text-[13px] text-muted-foreground">Evidencia de un hito</div>}
                </td>
                <td className="px-5 py-3.5 text-muted-foreground">{d.emprendimiento_id ? (names.get(d.emprendimiento_id) ?? `#${d.emprendimiento_id}`) : "—"}</td>
                <td className="px-5 py-3.5 text-muted-foreground">{d.fecha_subida ? formatDateTime(d.fecha_subida) : "—"}</td>
                <td className="px-5 py-3 text-right">
                  <div className="flex justify-end gap-2">
                    <a
                      href={`/documents/${d.documento_id}/download`}
                      className="inline-flex h-11 items-center rounded-xl border-[1.5px] border-border-strong px-3.5 text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
                      aria-label={`Descargar ${d.nombre}`}
                    >
                      Descargar
                    </a>
                    {canWrite && <DeleteDocumentButton id={d.documento_id} name={d.nombre} />}
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
