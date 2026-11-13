import 'package:go_router/go_router.dart';

import 'screens/coach_screen.dart';
import 'screens/conversations_screen.dart';

abstract final class AssistantRoutes {
  static const coach = '/coach';
  static const conversations = '/coach/conversations';
}

/// Pestaña «Coach» (se agrega en `app/router.dart`).
final List<RouteBase> assistantRoutes = [
  GoRoute(
    path: AssistantRoutes.coach,
    builder: (context, state) => const CoachScreen(),
    routes: [
      GoRoute(
        path: 'conversations',
        builder: (context, state) => const ConversationsScreen(),
      ),
    ],
  ),
];
