/** Presentación de los roles y módulos del sistema (ver design.md §3.1 y §8). */
export const ROLE_META: Record<string, { label: string; bg: string; fg: string; bar: string }> = {
  administrador: { label: "Administrador", bg: "#0A1A44", fg: "#FFFFFF", bar: "#0A1A44" },
  coordinador: { label: "Coordinador", bg: "#DCE6FF", fg: "#0F2F8C", bar: "#1F4FD6" },
  asesor: { label: "Asesor / Mentor", bg: "#FFE3E8", fg: "#8F0F25", bar: "#D61F3A" },
  emprendedor: { label: "Emprendedor", bg: "#DDF3E7", fg: "#0A5C39", bar: "#0E7A4F" },
};

export const roleLabel = (name: string | null): string =>
  (name && ROLE_META[name]?.label) || name || "Sin rol";

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
