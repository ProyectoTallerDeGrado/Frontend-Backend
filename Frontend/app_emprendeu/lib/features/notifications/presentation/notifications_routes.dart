import 'package:go_router/go_router.dart';

import 'screens/notifications_screen.dart';

abstract final class NotificationsRoutes {
  static const inbox = '/notifications';
}

/// Bandeja de avisos (fuera de la barra inferior; se abre desde la campana).
final List<RouteBase> notificationsRoutes = [
  GoRoute(
    path: NotificationsRoutes.inbox,
    builder: (context, state) => const NotificationsScreen(),
  ),
];
