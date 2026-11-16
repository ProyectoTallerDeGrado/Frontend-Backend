/**
 * Textos de la landing. Sin estadísticas inventadas. Confirmado con el CIE-U: postular y participar es
 * gratis, es para estudiantes de la UAGRM y el coach IA funciona también sin internet.
 * Todo el texto visible vive aquí; los componentes solo deciden la forma.
 */

/** Etiquetas de acción: una sola forma de decir cada cosa en toda la página. */
export const CTA = {
  apply: "Postula tu emprendimiento",
  applyShort: "Postular",
  staff: "Personal CIE-U",
  panel: "Ir al panel",
  howItWorks: "Ver cómo funciona",
} as const;

/**
 * Enlace de descarga de la app del emprendedor (Play Store o APK). Mientras sea `null`, la landing
 * indica entrar desde la app sin enlazar a ningún sitio.
 */
export const APP_DOWNLOAD_URL: string | null = null;

/** Anclas de la cabecera (escritorio). */
export const NAV_LINKS = [
  { href: "#problema", label: "El problema" },
  { href: "#camino", label: "El camino" },
  { href: "#app", label: "La app" },
  { href: "#esencial", label: "Lo esencial" },
  { href: "#preguntas", label: "Preguntas" },
] as const;

/** Palabras que rotan en el titular del hero («Tu ___ no debería morir en un cuaderno»). */
export const HERO_WORDS = ["idea", "app", "tienda", "marca", "startup"] as const;

/** Lo que gira alrededor de la idea en el hero. */
export const ORBIT_LABELS = ["Mentorías", "Coach IA", "Retos y XP", "Capacitaciones", "Comunidad"] as const;

/** El problema y su respuesta: cada nota se voltea en la sección «El giro». */
export const PROBLEMS = [
  { problem: "No sé por dónde empezar", answer: "Un camino en 4 etapas, con retos claros", icon: "route" },
  { problem: "Nadie revisa lo que hago", answer: "Un asesor asignado que te acompaña", icon: "mentor" },
  { problem: "Me trabo y no tengo a quién preguntar", answer: "Coach IA a cualquier hora, también sin internet", icon: "bot" },
  { problem: "Lo dejo para después", answer: "Retos con XP, y avisos si te frenas", icon: "trophy" },
  { problem: "No sé nada de finanzas", answer: "Capacitaciones del programa", icon: "cap" },
  { problem: "Estoy solo en esto", answer: "Tu equipo y una comunidad que emprende", icon: "people" },
] as const;

export type ProblemIcon = (typeof PROBLEMS)[number]["icon"];

export const STAGES = [
  {
    name: "Preincubación",
    text: "Validas el problema, hablas con posibles clientes y defines tu propuesta de valor.",
  },
  {
    name: "Incubación",
    text: "Construyes un prototipo, haces tus primeras ventas de prueba y ordenas los números.",
  },
  {
    name: "Crecimiento",
    text: "Presentas tu plan financiero y creces con clientes reales.",
  },
  {
    name: "Graduación",
    text: "Tu emprendimiento camina solo y sigue en la red del CIE-U.",
  },
] as const;

/** Lo que contiene la app (cada paso cambia la pantalla del teléfono). */
export const APP_FEATURES = [
  {
    key: "home",
    title: "Inicio: tu semana de un vistazo",
    text: "Tu nivel, el siguiente reto y los compromisos que acordaste con tu asesor, apenas abres la app.",
  },
  {
    key: "journey",
    title: "Camino: retos que suman XP",
    text: "Cada etapa tiene retos. Al cumplirlos ganas XP e insignias, subes de nivel y desbloqueas la siguiente parte del camino.",
  },
  {
    key: "mentoring",
    title: "Mentorías: agenda con tu asesor",
    text: "Eliges un horario libre de tu asesor y listo. Después de cada sesión quedan sus recomendaciones y tus compromisos.",
  },
  {
    key: "coach",
    title: "Coach IA: pregunta sin vergüenza",
    text: "Responde con los materiales del CIE-U y te muestra de dónde sacó cada respuesta. Lo descargas una vez y funciona sin internet.",
  },
] as const;

export type AppFeatureKey = (typeof APP_FEATURES)[number]["key"];

/** Pestañas de la barra inferior de la app de ejemplo. */
export const PHONE_TABS = ["Inicio", "Camino", "Coach", "Mentorías", "Perfil"] as const;

/** «Y detrás de la app, personas»: el seguimiento del personal, contado desde el lado del estudiante. */
export const STAFF_POINTS = [
  { icon: "alert", text: "Si te frenas, salta una alerta y alguien te busca." },
  { icon: "calendar", text: "Tu asesor ve tus sesiones, avances y compromisos." },
  { icon: "chart", text: "La coordinación decide contigo cuándo pasas de etapa." },
] as const;

export type StaffIcon = (typeof STAFF_POINTS)[number]["icon"];

/** «Lo esencial»: solo datos confirmados. Fechas de convocatoria y contacto se agregan cuando el CIE-U los dé. */
export const ESSENTIALS = [
  { term: "Costo", detail: "Gratis. Postular y participar en el programa no cuesta nada." },
  { term: "Para quién", detail: "Estudiantes de la UAGRM, solos o con su equipo." },
  { term: "Tu idea", detail: "Puede estar verde: la preincubación existe para validarla." },
  { term: "Qué necesitas", detail: "Un celular para la app del emprendedor. El coach IA funciona también sin internet." },
  { term: "Dónde", detail: "En el CIE-U de la FCEE, UAGRM, Santa Cruz." },
] as const;

export const APPLY_STEPS = [
  {
    title: "Postula en línea",
    text: "Cuéntanos quién eres y de qué trata tu emprendimiento. Te toma unos minutos.",
  },
  {
    title: "La coordinación revisa",
    text: "El equipo del CIE-U lee tu postulación y te responde por correo.",
  },
  {
    title: "Entras al programa",
    text: "Recibes tu cuenta, instalas la app y empiezas por la preincubación con un asesor.",
  },
] as const;

export const FAQ = [
  {
    q: "¿Puedo postular con mi equipo?",
    a: "Sí. Un emprendimiento puede tener varios integrantes, y cada uno usa la app con su cuenta.",
  },
  {
    q: "¿Qué pasa si me atraso?",
    a: "Nadie te expulsa. Si tu emprendimiento se detiene o un compromiso se vence, tu asesor se entera y te busca para destrabarlo.",
  },
  {
    q: "¿Cómo consigo la app?",
    a: "Al entrar al programa recibes tu cuenta y te indicamos cómo instalarla. La web es solo para el personal del CIE-U.",
  },
  {
    q: "¿El coach funciona sin internet?",
    a: "Sí. Lo descargas desde tu perfil en la app y responde en el celular, sin conexión.",
  },
] as const;

/** Conversación de ejemplo del coach en la pantalla del teléfono. */
export const COACH_CHAT = {
  question: "¿Cómo valido si alguien pagaría por mi idea?",
  answer: "Habla con 5 posibles clientes antes de construir nada. Pregunta cómo resuelven hoy el problema.",
  source: "Guía de validación del CIE-U",
} as const;
