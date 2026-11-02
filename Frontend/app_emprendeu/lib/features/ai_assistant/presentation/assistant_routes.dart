import 'package:go_router/go_router.dart';

import 'screens/coach_screen.dart';

abstract final class AssistantRoutes {
  static const coach = '/coach';
}

/// Pestaña «Coach» (se agrega en `app/router.dart`).
final List<RouteBase> assistantRoutes = [
  GoRoute(
    path: AssistantRoutes.coach,
    builder: (context, state) => const CoachScreen(),
  ),
];
