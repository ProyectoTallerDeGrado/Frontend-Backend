import type { Metadata } from "next";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { PermissionsEditor, getRoleMatrices, listRoles } from "@/features/users";

export const metadata: Metadata = { title: "Roles y permisos · CIE-U" };

export default async function RolesPage() {
  const user = await requireSession();
  if (!hasPermission(user, "usuarios:consulta")) return <NoAccess section="Roles y permisos" />;

  const roles = await listRoles();
  const matrices = await getRoleMatrices(roles);
  return (
    <>
      <PageHeader
        title="Roles y permisos"
        subtitle="Define qué puede consultar, registrar, modificar y administrar cada rol."
      />
      <PermissionsEditor roles={roles} matrices={matrices} canEdit={hasPermission(user, "usuarios:administrativo")} />
    </>
  );
}
