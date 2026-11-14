import { notFound } from "next/navigation";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { listEntrepreneurOptions } from "@/features/entrepreneurs";
import { formatDateTime } from "@/lib/format";

import { getTraining, listParticipants } from "../server/queries";
import { ParticipantsPanel } from "./participants-panel";
import { TrainingFormSheet } from "./training-form";

/** CU27/CU28 · Detalle de una capacitación con sus participantes y asistencia. */
export async function TrainingDetailScreen({ id }: { id: number }) {
  const user = await requireSession();
  if (!hasPermission(user, "asesorias:consulta")) return <NoAccess section="Capacitaciones" />;

  const training = await getTraining(id);
  if (!training) notFound();
  const [participants, options] = await Promise.all([listParticipants(id), listEntrepreneurOptions()]);
  const canEdit = hasPermission(user, "asesorias:modificacion");

  return (
    <>
      <PageHeader
        title={training.titulo}
        back={{ href: "/training", label: "Capacitaciones" }}
        subtitle={[formatDateTime(training.fecha), training.modalidad, training.estado].filter((v) => v && v !== "—").join(" · ")}
        actions={canEdit ? <TrainingFormSheet training={training} /> : undefined}
      />
      {training.descripcion && <p className="mb-6 max-w-3xl text-[15px] leading-normal text-muted-foreground">{training.descripcion}</p>}
      <ParticipantsPanel
        trainingId={id}
        participants={participants}
        options={options}
        canEdit={canEdit}
        canAdd={hasPermission(user, "asesorias:registro")}
        closed={training.estado === "cancelada"}
      />
    </>
  );
}
