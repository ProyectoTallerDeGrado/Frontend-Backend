import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { listVentureOptions } from "@/features/ventures";

import {
  SESSIONS_PAGE_SIZE,
  getAvailability,
  listAdvisors,
  listAssignments,
  listMyAssignments,
  listMySessions,
  listSessions,
} from "../server/queries";
import type { SessionFilters, VentureOption } from "../types";
import { AssignmentsPanel } from "./assignments-panel";
import { AvailabilityPanel } from "./availability-panel";
import { SessionsView } from "./sessions-view";

const ADVISOR_ROLE = "asesor";

/** CU09 · Coordinación asigna asesores habilitados a emprendimientos. */
export async function AssignmentsScreen() {
  const user = await requireSession();
  if (!hasPermission(user, "asesorias:consulta")) return <NoAccess section="Asignaciones" />;

  const [advisors, assignments, ventures] = await Promise.all([
    listAdvisors(),
    listAssignments(),
    listVentureOptions(),
  ]);
  return (
    <>
      <PageHeader
        title="Asignaciones"
        subtitle="Habilita asesores y asígnalos a los emprendimientos que acompañarán."
      />
      <AssignmentsPanel
        advisors={advisors}
        assignments={assignments}
        ventures={ventures}
        canEdit={hasPermission(user, "asesorias:registro") && user.rol !== ADVISOR_ROLE}
      />
    </>
  );
}

/** CU15 · El asesor define los horarios en que atiende. */
export async function AvailabilityScreen() {
  const user = await requireSession();
  if (user.rol !== ADVISOR_ROLE || !hasPermission(user, "asesorias:modificacion")) {
    return <NoAccess section="Mi disponibilidad" />;
  }
  const items = await getAvailability(user.usuario_id);
  return (
    <>
      <PageHeader
        title="Mi disponibilidad"
        subtitle="Define cuándo puedes atender mentorías; los emprendedores asignados agendan dentro de estos horarios."
      />
      <AvailabilityPanel mentorId={user.usuario_id} items={items} />
    </>
  );
}

/** CU23, CU16, CU17 y CU18 · Sesiones programadas y su seguimiento. */
export async function SessionsScreen({ filters }: { filters: SessionFilters }) {
  const user = await requireSession();
  if (!hasPermission(user, "asesorias:consulta")) return <NoAccess section="Sesiones" />;

  const isAdvisor = user.rol === ADVISOR_ROLE;
  const canWrite = hasPermission(user, "asesorias:registro");
  let ventures: VentureOption[] = [];
  if (canWrite) {
    // Un asesor solo registra sobre los emprendimientos que tiene asignados.
    ventures = isAdvisor
      ? (await listMyAssignments())
          .filter((a) => a.estado === "activa")
          .map((a) => ({ id: a.emprendimiento_id, name: a.emprendimiento ?? `Emprendimiento ${a.emprendimiento_id}` }))
      : await listVentureOptions();
  }

  const subtitle = isAdvisor
    ? "Tus mentorías, por estado y periodo. Registra lo que ocurrió, recomienda y deja compromisos."
    : "Todas las mentorías del CIE-U, por estado y periodo.";

  if (isAdvisor) {
    const sessions = await listMySessions(filters);
    return (
      <>
        <PageHeader title="Sesiones" subtitle={subtitle} />
        <SessionsView
          sessions={sessions}
          filters={filters}
          ventures={ventures}
          canWrite={canWrite}
          basePath="/mentoring/sessions"
        />
      </>
    );
  }
  const page = await listSessions(filters);
  return (
    <>
      <PageHeader title="Sesiones" subtitle={subtitle} />
      <SessionsView
        sessions={page.items}
        filters={filters}
        paging={{ page: page.page, pageSize: SESSIONS_PAGE_SIZE, total: page.total }}
        ventures={ventures}
        canWrite={canWrite}
        basePath="/mentoring/sessions"
      />
    </>
  );
}
