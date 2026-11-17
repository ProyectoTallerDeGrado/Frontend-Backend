import { AppShell } from "@/components/layout/app-shell";
import type { NavGroup, NavItem } from "@/components/layout/sidebar-nav";
import { HelpChat } from "@/features/ai_assistant";
import { countOpenAlerts } from "@/features/alerts";
import {
  GuidedTour,
  RestartTourButton,
  ROLE_LABELS,
  buildTourSteps,
  hasPermission,
  logoutAction,
  requireSession,
  tourGroupId,
} from "@/features/auth";

type Entry = NavItem & { permission?: string; hideForRole?: string; onlyForRole?: string };

/**
 * Menú agrupado por tarea. Cada sección declara el permiso que necesita para aparecer.
 * «Mi cuenta» no está aquí: es la tarjeta del usuario al pie del menú.
 */
const NAV: { label: string; items: Entry[] }[] = [
  {
    label: "Inicio",
    items: [
      { href: "/panel", label: "Resumen", icon: "dashboard", permission: "reportes:consulta" },
      { href: "/dashboard", label: "Indicadores", icon: "dashboard2", permission: "reportes:consulta", hideForRole: "emprendedor" },
      { href: "/reports", label: "Reportes", icon: "reports", permission: "reportes:consulta", hideForRole: "emprendedor" },
    ],
  },
  {
    label: "Programa",
    items: [
      { href: "/admissions", label: "Admisiones", icon: "admissions", permission: "emprendedores:registro", hideForRole: "emprendedor" },
      { href: "/entrepreneurs", label: "Emprendedores", icon: "entrepreneurs", permission: "emprendedores:consulta", hideForRole: "emprendedor" },
      { href: "/ventures", label: "Emprendimientos", icon: "ventures", permission: "emprendedores:consulta", hideForRole: "emprendedor" },
      { href: "/needs", label: "Necesidades", icon: "needs", permission: "seguimiento:consulta", hideForRole: "emprendedor" },
      { href: "/alerts", label: "Alertas", icon: "alerts", permission: "seguimiento:consulta", hideForRole: "emprendedor" },
      { href: "/health", label: "Salud", icon: "health", permission: "seguimiento:consulta", hideForRole: "emprendedor" },
    ],
  },
  {
    label: "Acompañamiento",
    items: [
      { href: "/mentoring/assignments", label: "Asignaciones", icon: "assignments", permission: "asesorias:registro", hideForRole: "asesor" },
      { href: "/mentoring/availability", label: "Mi disponibilidad", icon: "availability", permission: "asesorias:modificacion", onlyForRole: "asesor" },
      { href: "/mentoring/sessions", label: "Sesiones", icon: "sessions", permission: "asesorias:consulta" },
      { href: "/training", label: "Capacitaciones", icon: "training", permission: "asesorias:consulta", hideForRole: "emprendedor" },
    ],
  },
  {
    label: "Configuración",
    items: [
      { href: "/users", label: "Usuarios", icon: "users", permission: "usuarios:consulta" },
      { href: "/roles", label: "Roles y permisos", icon: "roles", permission: "usuarios:consulta" },
      { href: "/settings/tracking", label: "Parámetros", icon: "tracking", permission: "config:consulta" },
      { href: "/catalogs", label: "Catálogos y XP", icon: "catalogs", permission: "config:consulta" },
      { href: "/knowledge", label: "Base de conocimiento", icon: "knowledge", permission: "config:consulta", hideForRole: "emprendedor" },
      { href: "/audit", label: "Auditoría", icon: "audit", permission: "config:consulta" },
    ],
  },
];

/** Todo lo que cuelga de `(app)` exige sesión y se pinta dentro del shell. */
export default async function AppLayout({ children }: LayoutProps<"/">) {
  const user = await requireSession();
  const seesAlerts = user.rol !== "emprendedor" && hasPermission(user, "seguimiento:consulta");
  const openAlerts = seesAlerts ? await countOpenAlerts() : 0;
  const allowed = (item: Entry) =>
    item.hideForRole !== user.rol &&
    (!item.onlyForRole || item.onlyForRole === user.rol) &&
    (!item.permission || hasPermission(user, item.permission));

  const groups: NavGroup[] = NAV.map((group) => ({
    label: group.label,
    tourId: tourGroupId(group.label),
    items: group.items.filter(allowed).map(({ href, label, icon }) => ({
      href,
      label,
      icon,
      badge: href === "/alerts" ? openAlerts : undefined,
    })),
  })).filter((group) => group.items.length > 0);

  return (
    <AppShell
      user={{ name: `${user.nombre} ${user.apellido}`, roleLabel: ROLE_LABELS[user.rol ?? ""] ?? user.rol ?? "Sin rol" }}
      groups={groups}
      logoutAction={logoutAction}
      overlays={
        <>
          <HelpChat extra={<RestartTourButton />} />
          <GuidedTour
            steps={buildTourSteps({ firstName: user.nombre, groups })}
            autoStart={user.tutorial_completado_at === null}
          />
        </>
      }
    >
      {children}
    </AppShell>
  );
}
