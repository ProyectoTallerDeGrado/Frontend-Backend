import type { Metadata } from "next";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { NewUserDrawer, UsersView, listRoles } from "@/features/users";

export const metadata: Metadata = { title: "Usuarios · CIE-U" };

export default async function UsersPage({ searchParams }: PageProps<"/users">) {
  const user = await requireSession();
  if (!hasPermission(user, "usuarios:consulta")) return <NoAccess section="Usuarios" />;

  const { q, rol, page } = await searchParams;
  const roles = await listRoles();
  return (
    <>
      <PageHeader
        title="Usuarios"
        subtitle="Registra, modifica, habilita o deshabilita las cuentas de la plataforma."
        actions={hasPermission(user, "usuarios:registro") ? <NewUserDrawer roles={roles} /> : undefined}
      />
      <UsersView
        q={typeof q === "string" ? q : ""}
        rol={typeof rol === "string" ? rol : ""}
        page={Math.max(1, Number(typeof page === "string" ? page : 1) || 1)}
        currentUserId={user.usuario_id}
        canToggle={hasPermission(user, "usuarios:modificacion")}
        canChangeRole={hasPermission(user, "usuarios:administrativo")}
      />
    </>
  );
}
