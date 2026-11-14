import 'package:go_router/go_router.dart';

import 'screens/coach_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/own_documents_screen.dart';

abstract final class AssistantRoutes {
  static const coach = '/coach';
  static const conversations = '/coach/conversations';

  /// Pantalla completa, fuera de la barra inferior (se abre desde Perfil y Coach).
  static const ownFiles = '/ai-files';
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

/// Pantallas de la IA fuera de la barra inferior (se agregan en `app/router.dart`).
final List<RouteBase> assistantDetailRoutes = [
  GoRoute(
    path: AssistantRoutes.ownFiles,
    builder: (context, state) => const OwnDocumentsScreen(),
  ),
];
