import type { Metadata } from "next";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { RecentActivity, listAudit } from "@/features/audit";
import { hasPermission, requireSession } from "@/features/auth";
import { OverviewView, getOverview } from "@/features/indicators";

export const metadata: Metadata = { title: "Resumen · CIE-U" };

export default async function HomePage() {
  const user = await requireSession();
  if (!hasPermission(user, "reportes:consulta")) return <NoAccess section="el resumen" />;

  const [overview, recent] = await Promise.all([
    getOverview(),
    hasPermission(user, "config:consulta") ? listAudit({ pageSize: 4 }) : null,
  ]);
  return (
    <>
      <PageHeader
        title="Resumen de la plataforma"
        subtitle="Supervisa cuentas, servicios y la actividad administrativa reciente."
      />
      <div className="flex flex-col gap-6">
        <OverviewView overview={overview} />
        {recent && <RecentActivity entries={recent.items} />}
      </div>
    </>
  );
}
