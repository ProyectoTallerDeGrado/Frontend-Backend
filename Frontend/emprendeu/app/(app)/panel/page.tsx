import type { Metadata } from "next";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { RecentActivity, listAudit } from "@/features/audit";
import { hasPermission, requireSession } from "@/features/auth";
import { HealthAttentionCard, OverviewView, getHealth, getOverview } from "@/features/indicators";
import { AdvisorDashboardView, getAdvisorDashboardSnapshot } from "@/features/mentoring";
import { countOpenAlerts } from "@/features/alerts";

export const metadata: Metadata = { title: "Resumen · CIE-U" };

export default async function HomePage() {
  const user = await requireSession();
  if (user.rol === "asesor") {
    const [snapshot, health, openAlerts] = await Promise.all([
      getAdvisorDashboardSnapshot(),
      getHealth(),
      countOpenAlerts(),
    ]);
    return (
      <AdvisorDashboardView
        firstName={user.nombre}
        snapshot={snapshot}
        health={health}
        openAlerts={openAlerts}
        canManageAvailability={hasPermission(user, "asesorias:modificacion")}
      />
    );
  }
  if (!hasPermission(user, "reportes:consulta")) return <NoAccess section="el resumen" />;

  const seesHealth = user.rol !== "emprendedor" && hasPermission(user, "seguimiento:consulta");
  const [overview, recent, health] = await Promise.all([
    getOverview(),
    hasPermission(user, "config:consulta") ? listAudit({ pageSize: 5 }) : null,
    seesHealth ? getHealth() : null,
  ]);
  return (
    <>
      <PageHeader title={`Hola, ${user.nombre}`} subtitle="Así está el programa del CIE-U hoy." />
      <div className="flex flex-col gap-6">
        <OverviewView
          overview={overview}
          links={{
            alerts: user.rol !== "emprendedor" && hasPermission(user, "seguimiento:consulta"),
            ventures: user.rol !== "emprendedor" && hasPermission(user, "emprendedores:consulta"),
            users: hasPermission(user, "usuarios:consulta"),
          }}
        />
        {health && <HealthAttentionCard report={health} />}
        {recent && <RecentActivity entries={recent.items} />}
      </div>
    </>
  );
}
