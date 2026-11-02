import type { Metadata } from "next";

import { PageHeader } from "@/components/layout/page-header";
import { AccountView, requireSession } from "@/features/auth";

export const metadata: Metadata = { title: "Mi cuenta · CIE-U" };

export default async function AccountPage() {
  const user = await requireSession();
  return (
    <>
      <PageHeader title="Mi cuenta" subtitle="Consulta tus datos y cambia tu contraseña de acceso." />
      <AccountView user={user} />
    </>
  );
}
