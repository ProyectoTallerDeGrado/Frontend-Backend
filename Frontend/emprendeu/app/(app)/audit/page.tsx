import type { Metadata } from "next";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { AuditView, ExportAuditButton } from "@/features/audit";
import { hasPermission, requireSession } from "@/features/auth";

export const metadata: Metadata = { title: "Auditoría · CIE-U" };

export default async function AuditPage({ searchParams }: PageProps<"/audit">) {
  const user = await requireSession();
  if (!hasPermission(user, "config:consulta")) return <NoAccess section="Auditoría" />;

  const { categoria, page } = await searchParams;
  const category = typeof categoria === "string" ? categoria : "";
  return (
    <>
      <PageHeader
        title="Auditoría"
        subtitle="Registro de acciones sensibles realizadas en el sistema."
        actions={<ExportAuditButton categoria={category} />}
      />
      <AuditView categoria={category} page={Math.max(1, Number(typeof page === "string" ? page : 1) || 1)} />
    </>
  );
}
