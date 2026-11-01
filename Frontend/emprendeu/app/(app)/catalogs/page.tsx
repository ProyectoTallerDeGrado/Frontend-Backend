import type { Metadata } from "next";
import Link from "next/link";

import { NoAccess } from "@/components/layout/no-access";
import { PageHeader } from "@/components/layout/page-header";
import { hasPermission, requireSession } from "@/features/auth";
import { BadgesGrid, ChallengesTable, listBadges, listChallenges } from "@/features/gamification";
import { StageList, listStages } from "@/features/ventures";

export const metadata: Metadata = { title: "Catálogos y XP · CIE-U" };

const TABS = [
  { key: "etapas", label: "Etapas" },
  { key: "retos", label: "Retos" },
  { key: "insignias", label: "Insignias" },
] as const;

export default async function CatalogsPage({ searchParams }: PageProps<"/catalogs">) {
  const user = await requireSession();
  if (!hasPermission(user, "config:consulta")) return <NoAccess section="Catálogos y gamificación" />;

  const { tab } = await searchParams;
  const current = TABS.find((t) => t.key === tab)?.key ?? "etapas";
  const canEdit = hasPermission(user, "config:modificacion");
  const challenges = await listChallenges();
  const counts: Record<number, number> = {};
  for (const c of challenges) counts[c.etapa_id] = (counts[c.etapa_id] ?? 0) + 1;

  return (
    <>
      <PageHeader title="Catálogos y gamificación" subtitle="Etapas del ciclo de vida, retos, recompensas XP e insignias." />
      <div className="flex flex-col gap-5">
        <div className="flex flex-wrap gap-2" role="group" aria-label="Catálogo">
          {TABS.map((t) => (
            <Link
              key={t.key}
              href={`/catalogs?tab=${t.key}`}
              aria-current={t.key === current ? "true" : undefined}
              className={`inline-flex min-h-[46px] items-center rounded-xl border-[1.5px] px-[22px] text-[15px] font-semibold outline-none transition-all focus-visible:ring-3 focus-visible:ring-primary/30 ${t.key === current ? "border-primary bg-primary text-white" : "border-border-strong bg-card hover:bg-blue-50"}`}
            >
              {t.label}
            </Link>
          ))}
        </div>
        {current === "etapas" && <StageList stages={await listStages()} challengeCounts={counts} canEdit={canEdit} />}
        {current === "retos" && <ChallengesTable challenges={challenges} canEdit={canEdit} />}
        {current === "insignias" && <BadgesGrid badges={await listBadges()} />}
      </div>
    </>
  );
}
