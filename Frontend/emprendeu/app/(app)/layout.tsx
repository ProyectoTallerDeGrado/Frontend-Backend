import { AppShell } from "@/components/layout/app-shell";
import type { NavItem } from "@/components/layout/sidebar-nav";
import { ROLE_LABELS, hasPermission, logoutAction, requireSession } from "@/features/auth";

/** Qué permiso necesita cada sección para aparecer en el menú (sin `permission`: todo el personal). */
const NAV: (NavItem & { permission?: string; hideForRole?: string })[] = [
  { href: "/", label: "Resumen", icon: "dashboard", permission: "reportes:consulta" },
  { href: "/dashboard", label: "Dashboard", icon: "dashboard2", permission: "reportes:consulta", hideForRole: "emprendedor" },
  { href: "/reports", label: "Reportes", icon: "reports", permission: "reportes:consulta", hideForRole: "emprendedor" },
  { href: "/users", label: "Usuarios", icon: "users", permission: "usuarios:consulta" },
  { href: "/roles", label: "Roles y permisos", icon: "roles", permission: "usuarios:consulta" },
  { href: "/settings/tracking", label: "Parámetros", icon: "tracking", permission: "config:consulta" },
  { href: "/catalogs", label: "Catálogos y XP", icon: "catalogs", permission: "config:consulta" },
  { href: "/knowledge", label: "Base de conocimiento", icon: "knowledge", permission: "config:consulta", hideForRole: "emprendedor" },
  { href: "/audit", label: "Auditoría", icon: "audit", permission: "config:consulta" },
  { href: "/entrepreneurs", label: "Emprendedores", icon: "entrepreneurs", permission: "emprendedores:consulta", hideForRole: "emprendedor" },
  { href: "/ventures", label: "Emprendimientos", icon: "ventures", permission: "emprendedores:consulta", hideForRole: "emprendedor" },
  { href: "/alerts", label: "Alertas", icon: "alerts", permission: "seguimiento:consulta", hideForRole: "emprendedor" },
  { href: "/mentoring/assignments", label: "Asignaciones", icon: "assignments", permission: "asesorias:registro", hideForRole: "asesor" },
  { href: "/mentoring/availability", label: "Mi disponibilidad", icon: "availability", permission: "asesorias:modificacion" },
  { href: "/mentoring/sessions", label: "Sesiones", icon: "sessions", permission: "asesorias:consulta" },
  { href: "/account", label: "Mi cuenta", icon: "account" },
];

/** Todo lo que cuelga de `(app)` exige sesión y se pinta dentro del shell. */
export default async function AppLayout({ children }: LayoutProps<"/">) {
  const user = await requireSession();
  const nav = NAV.filter(
    (item) => item.hideForRole !== user.rol && (!item.permission || hasPermission(user, item.permission)),
  ).map(({ href, label, icon }) => ({
    href,
    label,
    icon,
  }));
  return (
    <AppShell
      user={{ name: `${user.nombre} ${user.apellido}`, roleLabel: ROLE_LABELS[user.rol ?? ""] ?? "Sin rol" }}
      nav={nav}
      logoutAction={logoutAction}
    >
      {children}
    </AppShell>
  );
}
