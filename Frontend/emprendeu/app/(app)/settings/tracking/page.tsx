import type { Metadata } from "next";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { TrackingForm, getTrackingSettings } from "@/features/alerts";
import { hasPermission, requireSession } from "@/features/auth";

export const metadata: Metadata = { title: "Parámetros · CIE-U" };

export default async function TrackingPage() {
  const user = await requireSession();
  if (!hasPermission(user, "config:consulta")) return <NoAccess section="Parámetros de seguimiento" />;

  const settings = await getTrackingSettings();
  return (
    <>
      <PageHeader
        title="Parámetros de seguimiento"
        subtitle="Reglas que usa el sistema para detectar inactividad y riesgo de deserción."
      />
      <TrackingForm
        initial={settings}
        canEdit={hasPermission(user, "config:modificacion")}
        canEvaluate={hasPermission(user, "config:administrativo")}
      />
    </>
  );
}
