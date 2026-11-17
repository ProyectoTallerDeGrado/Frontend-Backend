/// Un aviso de la bandeja (también llega como notificación push si hay Firebase).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.route,
  });

  final int id;

  /// `sesion_cancelada`, `compromiso_nuevo`, `capacitacion_nueva`, … (ver backend).
  final String kind;
  final String title;
  final String body;

  /// Pantalla de la app a la que lleva (p. ej. `/mentoring/session/3`).
  final String? route;
  final bool read;
  final DateTime createdAt;

  AppNotification markRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    route: route,
    read: true,
    createdAt: createdAt,
  );
}

/// Una página de la bandeja.
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.page,
    required this.total,
  });

  final List<AppNotification> items;
  final int page;
  final int total;
}

const notificationsPageSize = 20;

/// Un push recibido en el celular (con la app abierta o al tocarlo).
class PushNotice {
  const PushNotice({this.title, this.body, this.route});

  final String? title;
  final String? body;
  final String? route;
}

/// Pantallas a las que puede llevar un aviso. Una ruta fuera de esta lista se
/// ignora: el contenido del push no decide a dónde navega la app.
const _allowedRoutePrefixes = [
  '/home',
  '/journey',
  '/xp',
  '/mentoring',
  '/coach',
  '/account',
  '/training',
  '/venture',
];

/// La ruta si es una pantalla conocida de la app; si no, `null`.
String? safeRoute(String? route) {
  if (route == null || route.isEmpty || !route.startsWith('/')) return null;
  if (route.contains('..') || route.contains('://')) return null;
  final ok = _allowedRoutePrefixes.any(
    (p) => route == p || route.startsWith('$p/'),
  );
  return ok ? route : null;
}
