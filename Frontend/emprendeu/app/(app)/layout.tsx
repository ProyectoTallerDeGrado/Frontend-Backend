import { AppShell } from "@/components/layout/app-shell";
import type { NavItem } from "@/components/layout/sidebar-nav";
import { ROLE_LABELS, hasPermission, logoutAction, requireSession } from "@/features/auth";

/** Qué permiso necesita cada sección para aparecer en el menú. */
const NAV: (NavItem & { permission: string })[] = [
  { href: "/", label: "Resumen", icon: "dashboard", permission: "reportes:consulta" },
  { href: "/users", label: "Usuarios", icon: "users", permission: "usuarios:consulta" },
  { href: "/roles", label: "Roles y permisos", icon: "roles", permission: "usuarios:consulta" },
  { href: "/settings/tracking", label: "Parámetros", icon: "tracking", permission: "config:consulta" },
  { href: "/catalogs", label: "Catálogos y XP", icon: "catalogs", permission: "config:consulta" },
  { href: "/audit", label: "Auditoría", icon: "audit", permission: "config:consulta" },
];

/** Todo lo que cuelga de `(app)` exige sesión y se pinta dentro del shell. */
export default async function AppLayout({ children }: LayoutProps<"/">) {
  const user = await requireSession();
  const nav = NAV.filter((item) => hasPermission(user, item.permission)).map(({ href, label, icon }) => ({
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
