/**
 * Pasos del tutorial guiado del panel. Módulo sin `'use client'`: el layout (servidor) arma
 * los pasos con el menú ya filtrado por permisos y se los pasa al componente cliente.
 */

export type TourStep = {
  id: string;
  /** Selector `[data-tour=…]` del elemento a resaltar; sin él, el globo va centrado. */
  target?: string;
  title: string;
  body: string;
  /** Pantallas del grupo, con lo que se hace en cada una. */
  items?: { label: string; text: string }[];
};

export type TourGroup = { label: string; items: { href: string; label: string }[] };

/** Qué se hace en cada pantalla del menú (texto del globo del tutorial). */
const SCREEN_TEXT: Record<string, string> = {
  "/panel": "las cifras del programa hoy y la actividad reciente.",
  "/dashboard": "cómo avanzan los emprendimientos, con filtros de periodo y etapa.",
  "/reports": "reportes con vista previa, descargables en Excel o CSV.",
  "/admissions": "las postulaciones: admitir crea la cuenta y el emprendimiento.",
  "/entrepreneurs": "registrar emprendedores y buscarlos por nombre, correo o documento.",
  "/ventures": "cada emprendimiento: equipo, etapa, progreso, documentos e historial.",
  "/needs": "las dificultades que reportan los emprendedores para atenderlas.",
  "/alerts": "avisos de inactividad y riesgo para revisar, atender o descartar.",
  "/health": "el puntaje de salud, del emprendimiento más urgente al que mejor va.",
  "/mentoring/assignments": "habilitar asesores y asignarlos a emprendimientos.",
  "/mentoring/availability": "los horarios en que los emprendedores pueden agendarte.",
  "/mentoring/sessions": "las mentorías: registrar sesiones, recomendaciones y compromisos.",
  "/training": "talleres y charlas: participantes y asistencia.",
  "/users": "crear cuentas, cambiar su rol y habilitarlas o deshabilitarlas.",
  "/roles": "qué puede consultar, registrar, modificar y administrar cada rol.",
  "/settings/tracking": "las reglas que detectan inactividad y riesgo de deserción.",
  "/catalogs": "etapas, retos, XP e insignias del programa.",
  "/knowledge": "los documentos con los que responde el coach IA.",
  "/audit": "el registro de acciones sensibles del sistema.",
};

const GROUP_INTRO: Record<string, string> = {
  Inicio: "Para ver cómo va el programa de un vistazo.",
  Programa: "El día a día de emprendedores y emprendimientos.",
  Acompañamiento: "Mentorías y capacitaciones.",
  Configuración: "Cuentas, permisos y reglas del sistema.",
};

/** `data-tour` de un grupo del menú (lo usa `SidebarNav`). */
export function tourGroupId(label: string): string {
  return `nav-group-${label
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")}`;
}

export function buildTourSteps({ firstName, groups }: { firstName: string; groups: TourGroup[] }): TourStep[] {
  const steps: TourStep[] = [
    {
      id: "welcome",
      title: `¡Hola, ${firstName}! Bienvenido a EmprendeU`,
      body: "Te mostramos en un minuto dónde está cada cosa. Puedes saltar el tutorial cuando quieras y repetirlo desde el botón de ayuda.",
    },
    {
      id: "nav",
      target: "nav",
      title: "El menú",
      body: "Aquí están todas las pantallas, agrupadas por tarea. Solo ves las que tu rol tiene permitidas. En el celular se abre con el botón de menú, arriba a la derecha.",
    },
  ];
  for (const group of groups) {
    if (group.items.length === 0) continue;
    steps.push({
      id: tourGroupId(group.label),
      target: tourGroupId(group.label),
      title: group.label,
      body: GROUP_INTRO[group.label] ?? "Pantallas de este grupo:",
      items: group.items.map((item) => ({ label: item.label, text: SCREEN_TEXT[item.href] ?? "" })),
    });
  }
  steps.push(
    {
      id: "account",
      target: "account",
      title: "Tu cuenta",
      body: "Tu tarjeta lleva a «Mi cuenta», donde ves tus datos y cambias tu contraseña. Debajo está «Cerrar sesión».",
    },
    {
      id: "help",
      target: "help",
      title: "¿Dudas? Pregúntale al asistente",
      body: "Este botón abre el asistente de ayuda: pregúntale cómo hacer cualquier cosa en el sistema. Desde ahí también puedes repetir este tutorial.",
    },
    {
      id: "done",
      title: "¡Listo para empezar!",
      body: "Ya conoces el panel. Elige una pantalla del menú para empezar y, si te pierdes, el asistente de ayuda está siempre abajo a la derecha.",
    },
  );
  return steps;
}
