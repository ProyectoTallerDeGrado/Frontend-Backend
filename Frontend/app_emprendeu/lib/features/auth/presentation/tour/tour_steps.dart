/// Un paso del tutorial guiado de la app: qué pestaña mostrar y qué resaltar.
class TourStep {
  const TourStep({
    required this.id,
    required this.tab,
    required this.title,
    required this.body,
    this.target,
  });

  final String id;

  /// Índice de la pestaña de la barra inferior donde ocurre el paso.
  final int tab;

  /// Identificador del `TourTarget` a resaltar; `null` = globo centrado.
  final String? target;
  final String title;
  final String body;
}

/// Índices de las pestañas (mismo orden que `AppShell`).
abstract final class TourTab {
  static const home = 0;
  static const journey = 1;
  static const mentoring = 2;
  static const coach = 3;
  static const account = 4;
}

/// Pasos del recorrido. [firstName] personaliza la bienvenida.
List<TourStep> buildTourSteps({String firstName = ''}) {
  final name = firstName.trim();
  return [
    TourStep(
      id: 'welcome',
      tab: TourTab.home,
      title: name.isEmpty ? '¡Bienvenido a EmprendeU!' : '¡Hola, $name!',
      body:
          'Te mostramos en un minuto cómo usar la app para avanzar con tu '
          'emprendimiento. Puedes saltarte el recorrido cuando quieras.',
    ),
    const TourStep(
      id: 'nav',
      tab: TourTab.home,
      target: 'nav',
      title: 'Tu barra de navegación',
      body:
          'Abajo tienes las cinco secciones: Inicio, Camino, Mentorías, Coach '
          'y Perfil. Toca una para cambiar de pantalla.',
    ),
    const TourStep(
      id: 'home-progress',
      tab: TourTab.home,
      target: 'home-progress',
      title: 'Inicio: tu progreso',
      body:
          'Aquí ves tu etapa, tu nivel y los puntos de experiencia (XP) que '
          'vas ganando al cumplir retos.',
    ),
    const TourStep(
      id: 'home-challenge',
      tab: TourTab.home,
      target: 'home-challenge',
      title: 'Tu próximo reto',
      body:
          'Te sugerimos qué hacer ahora. Tócalo para abrir el Camino y '
          'resolverlo. Debajo encontrarás tus compromisos y avances.',
    ),
    const TourStep(
      id: 'home-bell',
      tab: TourTab.home,
      target: 'home-bell',
      title: 'Avisos',
      body:
          'La campana reúne los avisos del CIE-U: mentorías, capacitaciones '
          'y novedades de tu emprendimiento.',
    ),
    const TourStep(
      id: 'journey',
      tab: TourTab.journey,
      target: 'journey-header',
      title: 'Camino: tu ruta de retos',
      body:
          'Cada etapa tiene retos en orden. Cúmplelos para ganar XP, subir de '
          'nivel y desbloquear insignias. Cumplir un reto requiere conexión.',
    ),
    const TourStep(
      id: 'mentoring-book',
      tab: TourTab.mentoring,
      target: 'mentoring-book',
      title: 'Mentorías: agenda una sesión',
      body:
          'Elige a tu asesor, el día y un turno libre. Si tu etapa aún no lo '
          'permite, aquí verás el motivo.',
    ),
    const TourStep(
      id: 'mentoring-history',
      tab: TourTab.mentoring,
      target: 'mentoring-history',
      title: 'Historial y tareas',
      body:
          'Revisa la historia de tu emprendimiento y las tareas y '
          'compromisos que dejó cada sesión.',
    ),
    const TourStep(
      id: 'coach',
      tab: TourTab.coach,
      target: 'coach-input',
      title: 'Coach IA',
      body:
          'Escribe tu duda y el Coach responde con las guías del CIE-U y '
          'te muestra sus fuentes. Si instalas la IA en tu celular, también '
          'funciona sin internet.',
    ),
    const TourStep(
      id: 'account-venture',
      tab: TourTab.account,
      target: 'account-venture',
      title: 'Perfil: tu emprendimiento',
      body:
          'Consulta y edita los datos de tu emprendimiento, y registra tus '
          'hitos con evidencia.',
    ),
    const TourStep(
      id: 'account-xp',
      tab: TourTab.account,
      target: 'account-xp',
      title: 'XP e insignias',
      body: 'Tu nivel, tus insignias y el historial de puntos ganados.',
    ),
    const TourStep(
      id: 'account-ai',
      tab: TourTab.account,
      target: 'account-ai',
      title: 'IA en tu celular',
      body:
          'Descarga la IA para usar el Coach sin internet. Tus archivos no '
          'salen del teléfono.',
    ),
    const TourStep(
      id: 'account-menu',
      tab: TourTab.account,
      target: 'account-menu',
      title: 'Más accesos',
      body:
          'Necesidades y dificultades, documentos del emprendimiento y '
          'capacitaciones. Al final puedes cambiar tu contraseña o cerrar '
          'sesión, y repetir este tutorial.',
    ),
    const TourStep(
      id: 'done',
      tab: TourTab.home,
      title: '¡Listo para empezar!',
      body:
          'Cuando quieras repetir este recorrido, entra a Perfil y toca '
          '«Ver el tutorial de la app». ¡Mucho éxito!',
    ),
  ];
}
