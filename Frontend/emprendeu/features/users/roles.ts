/** Presentación de los roles y módulos del sistema (ver design.md §3.1 y §8). */
export const ROLE_META: Record<string, { label: string; bg: string; fg: string; bar: string }> = {
  administrador: { label: "Administrador", bg: "#0A1A44", fg: "#FFFFFF", bar: "#0A1A44" },
  coordinador: { label: "Coordinador", bg: "#DCE6FF", fg: "#0F2F8C", bar: "#1F4FD6" },
  asesor: { label: "Asesor / Mentor", bg: "#FFE3E8", fg: "#8F0F25", bar: "#D61F3A" },
  emprendedor: { label: "Emprendedor", bg: "#DDF3E7", fg: "#0A5C39", bar: "#0E7A4F" },
};

/** Roles que vienen del sistema: no se renombran ni se eliminan (espejo de `SYSTEM_ROLES` del backend). */
export const SYSTEM_ROLES: readonly string[] = ["administrador", "coordinador", "asesor", "emprendedor"];

/** Color de los roles personalizados. */
const CUSTOM_ROLE_META = { bg: "#FFF0CC", fg: "#6B4700", bar: "#B77900" };

const capitalize = (s: string): string => s.charAt(0).toUpperCase() + s.slice(1);

export const roleLabel = (name: string | null): string =>
  (name && (ROLE_META[name]?.label ?? capitalize(name))) || "Sin rol";

export const roleMeta = (name: string | null) =>
  (name && ROLE_META[name]) || (name ? { label: roleLabel(name), ...CUSTOM_ROLE_META } : undefined);

/** Plantillas al crear un rol: qué acciones se marcan en cada módulo. */
export const ROLE_TEMPLATES = [
  { key: "vacio", label: "Sin permisos" },
  { key: "lectura", label: "Solo lectura (consulta en todos los módulos)" },
] as const;

export const PERMISSION_MODULES = [
  { key: "usuarios", label: "Usuarios y roles" },
  { key: "emprendedores", label: "Emprendedores y emprendimientos" },
  { key: "asesorias", label: "Asesorías y mentorías" },
  { key: "seguimiento", label: "Seguimiento y etapas" },
  { key: "ia", label: "Asistente inteligente" },
  { key: "reportes", label: "Indicadores y reportes" },
  { key: "config", label: "Configuración del sistema" },
] as const;

export const PERMISSION_ACTIONS = [
  { key: "consulta", label: "Consulta" },
  { key: "registro", label: "Registro" },
  { key: "modificacion", label: "Modificación" },
  { key: "administrativo", label: "Administrativo" },
] as const;

export const AVATAR_COLORS: [string, string][] = [
  ["#DCE6FF", "#0F2F8C"],
  ["#FFE3E8", "#8F0F25"],
  ["#DDF3E7", "#0A5C39"],
  ["#FFF0CC", "#6B4700"],
  ["#E8E2FF", "#3C2A9B"],
];
