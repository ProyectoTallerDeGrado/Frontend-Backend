/** Preguntas sugeridas en el chat de ayuda según la pantalla en la que está la persona. */
const BY_ROUTE: [prefix: string, questions: string[]][] = [
  ["/ventures", ["¿Cómo avanzo un emprendimiento de etapa?", "¿Cómo subo un documento del emprendimiento?"]],
  ["/entrepreneurs", ["¿Cómo registro un emprendedor nuevo?", "¿Qué pasa con la contraseña temporal?"]],
  ["/admissions", ["¿Qué pasa al admitir una postulación?"]],
  ["/alerts", ["¿Qué diferencia hay entre revisada y atendida?", "¿De dónde salen las alertas?"]],
  ["/health", ["¿Cómo se calcula el puntaje de salud?"]],
  ["/needs", ["¿Cómo marco una necesidad como resuelta?"]],
  ["/mentoring/assignments", ["¿Cómo asigno un asesor a un emprendimiento?"]],
  ["/mentoring/availability", ["¿Cómo agrego un horario de atención?"]],
  ["/mentoring/sessions", ["¿Cómo registro una sesión realizada?", "¿Cómo creo un compromiso?"]],
  ["/training", ["¿Cómo registro la asistencia a una capacitación?"]],
  ["/users", ["¿Cómo creo un usuario nuevo?", "¿Cómo deshabilito una cuenta?"]],
  ["/roles", ["¿Cómo cambio los permisos de un rol?"]],
  ["/settings/tracking", ["¿Para qué sirven los parámetros de seguimiento?"]],
  ["/catalogs", ["¿Qué son los retos y la XP?"]],
  ["/knowledge", ["¿Cómo subo un documento al coach IA?"]],
  ["/reports", ["¿Cómo descargo un reporte en Excel?"]],
  ["/audit", ["¿Qué registra la auditoría?"]],
  ["/account", ["¿Cómo cambio mi contraseña?"]],
];

const GENERAL = ["¿Qué puedo hacer en el sistema?", "¿Dónde encuentro cada pantalla?"];

export function helpSuggestionsFor(pathname: string): string[] {
  const match = BY_ROUTE.filter(([prefix]) => pathname === prefix || pathname.startsWith(`${prefix}/`)).sort(
    (a, b) => b[0].length - a[0].length,
  )[0];
  return [...(match?.[1] ?? []), ...GENERAL].slice(0, 3);
}
