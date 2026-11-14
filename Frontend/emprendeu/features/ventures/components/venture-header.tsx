import { PageHeader } from "@/components/layout/page-header";
import { StatusPill, type PillTone } from "@/components/data/status-pill";
import { TabNav, type TabItem } from "@/components/data/tab-nav";
import { hasPermission, requireSession } from "@/features/auth";
import { listEntrepreneurOptions } from "@/features/entrepreneurs";

import { getVenture, listStages } from "../server/queries";
import { nextStage } from "../stages";
import { AdvanceStageSheet } from "./advance-stage-sheet";
import { StageTrack } from "./stage-track";
import { TeamSheet } from "./team-sheet";
import { EditVentureSheet } from "./venture-form-sheet";

const STATE_TONE: Record<string, PillTone> = { activo: "success", pausado: "warning", cerrado: "neutral" };

/** Pestañas de la ficha que puede ver el usuario (las tres primeras piden `seguimiento:consulta`). */
export function ventureTabs(ventureId: number, canFollow: boolean): TabItem[] {
  const base = `/ventures/${ventureId}`;
  return [
    ...(canFollow
      ? [
          { href: `${base}/progress`, label: "Progreso" },
          { href: `${base}/follow-up`, label: "Seguimiento" },
          { href: `${base}/stages`, label: "Etapas" },
        ]
      : []),
    { href: `${base}/documents`, label: "Documentos" },
    { href: `${base}/history`, label: "Historial" },
  ];
}

/** Primera pestaña disponible: a dónde lleva el nombre del emprendimiento en la lista. */
export function ventureHref(ventureId: number, canFollow: boolean): string {
  return ventureTabs(ventureId, canFollow)[0].href;
}

/**
 * Cabecera común de la ficha de un emprendimiento (layout de `/ventures/[id]`): datos,
 * acciones de coordinación, trayecto de etapas y pestañas.
 */
export async function VentureHeader({ ventureId }: { ventureId: number }) {
  const user = await requireSession();
  const [venture, stages] = await Promise.all([getVenture(ventureId), listStages()]);
  const canFollow = hasPermission(user, "seguimiento:consulta");
  const canChangeStage = hasPermission(user, "seguimiento:modificacion");
  const canEdit = hasPermission(user, "emprendedores:modificacion");
  const entrepreneurs = canEdit ? await listEntrepreneurOptions() : [];
  const next = nextStage(stages, venture.etapa_actual);
  const members = venture.integrantes.length;

  return (
    <div className="mb-7">
      <PageHeader
        title={venture.nombre}
        back={{ href: "/ventures", label: "Emprendimientos" }}
        subtitle={venture.descripcion ?? undefined}
        meta={
          <>
            {venture.estado && (
              <StatusPill tone={STATE_TONE[venture.estado] ?? "neutral"} dot className="capitalize">
                {venture.estado}
              </StatusPill>
            )}
            {venture.sector && <StatusPill tone="info">{venture.sector}</StatusPill>}
            <span className="text-sm text-muted-foreground">
              {members === 0 ? "Sin integrantes" : members === 1 ? "1 integrante" : `${members} integrantes`}
            </span>
          </>
        }
        actions={
          canEdit || canChangeStage ? (
            <>
              {canEdit && <TeamSheet venture={venture} entrepreneurs={entrepreneurs} />}
              {canEdit && <EditVentureSheet venture={venture} />}
              {canChangeStage && next && <AdvanceStageSheet venture={venture} next={next} />}
            </>
          ) : undefined
        }
      />
      <section aria-label="Trayecto por etapas" className="mb-6 rounded-2xl border border-border bg-card px-5 pt-5 pb-4">
        <StageTrack stages={stages} current={venture.etapa_actual} />
      </section>
      <TabNav label="Secciones del emprendimiento" tabs={ventureTabs(ventureId, canFollow)} />
    </div>
  );
}
