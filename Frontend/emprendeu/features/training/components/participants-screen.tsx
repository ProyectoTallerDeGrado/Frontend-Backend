import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { listEntrepreneurOptions } from "@/features/entrepreneurs";

import { getTraining, listParticipants } from "../server/queries";
import { AddParticipantForm } from "./add-participant-form";
import { AttendanceButtons } from "./attendance-buttons";

/** CU28 · Participantes y asistencia de una capacitación (la coordinación registra; el asesor consulta). */
export async function ParticipantsScreen({ trainingId }: { trainingId: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "asesorias:consulta")) return <NoAccess section="Participantes" />;
  const canManage = user.rol !== "asesor" && hasPermission(user, "asesorias:registro");
  const [training, participants] = await Promise.all([getTraining(trainingId), listParticipants(trainingId)]);
  const open = training.estado === "publicada" || training.estado === "realizada";
  const enrolled = new Set(participants.map((p) => p.emprendedor_id));
  const options = canManage && open ? (await listEntrepreneurOptions()).filter((o) => !enrolled.has(o.id)) : [];

  return (
    <>
      <PageHeader
        title={`Participantes · ${training.titulo}`}
        subtitle="Quién está inscrito y si asistió. Una persona no puede repetirse en la misma capacitación."
      />
      <Link href="/training" className="mb-5 inline-flex min-h-11 items-center text-sm font-semibold text-primary">
        ← Volver a capacitaciones
      </Link>
      {!open && (
        <p className="mb-5 rounded-xl bg-blue-50 px-4 py-3 text-sm">
          Esta capacitación está en estado «{training.estado}»; solo se registran participantes y asistencia cuando está publicada
          o realizada.
        </p>
      )}
      {canManage && open && <AddParticipantForm trainingId={trainingId} options={options} />}
      <div className="overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[720px] border-collapse text-left text-sm">
          <thead>
            <tr className="bg-[#f4f6fb] text-[12px] font-bold tracking-[.06em] text-muted-foreground uppercase">
              <th scope="col" className="px-5 py-3.5">Emprendedor</th>
              <th scope="col" className="px-5 py-3.5">Documento</th>
              <th scope="col" className="px-5 py-3.5">Asistencia</th>
              {canManage && open && <th scope="col" className="px-5 py-3.5"><span className="sr-only">Registrar</span></th>}
            </tr>
          </thead>
          <tbody>
            {participants.length === 0 && (
              <tr>
                <td colSpan={4} className="px-5 py-10 text-center text-muted-foreground">
                  Todavía no hay participantes.
                </td>
              </tr>
            )}
            {participants.map((p) => {
              const name = `${p.nombre ?? ""} ${p.apellido ?? ""}`.trim() || `Emprendedor ${p.emprendedor_id}`;
              return (
                <tr key={p.emprendedor_id} className="border-t border-[#eef2fa] align-middle">
                  <td className="px-5 py-3.5">
                    <div className="font-semibold">{name}</div>
                    <div className="text-[13px] text-muted-foreground">{p.email}</div>
                  </td>
                  <td className="px-5 py-3.5">{p.documento_identidad ?? "—"}</td>
                  <td className="px-5 py-3.5">
                    {p.asistencia === null ? (
                      <span className="text-muted-foreground">Pendiente</span>
                    ) : p.asistencia ? (
                      <span className="font-semibold text-success-foreground">Asistió</span>
                    ) : (
                      <span className="font-semibold text-[#8f0f25]">No asistió</span>
                    )}
                  </td>
                  {canManage && open && (
                    <td className="px-5 py-3 text-right">
                      <AttendanceButtons trainingId={trainingId} emprendedorId={p.emprendedor_id} name={name} attended={p.asistencia} />
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </>
  );
}
