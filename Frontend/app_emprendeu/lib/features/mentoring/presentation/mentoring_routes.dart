import 'package:go_router/go_router.dart';

import 'screens/book_session_screen.dart';
import 'screens/history_screen.dart';
import 'screens/mentoring_screen.dart';
import 'screens/session_detail_screen.dart';
import 'screens/tasks_screen.dart';

abstract final class MentoringRoutes {
  static const sessions = '/mentoring';
  static const book = '/mentoring/book';
  static const history = '/mentoring/history';
  static const tasks = '/mentoring/tasks';

  static String session(int id) => '/mentoring/session/$id';
}

/// Pestaña «Mentorías» y su pantalla de agendar (se agregan en `app/router.dart`).
final List<RouteBase> mentoringRoutes = [
  GoRoute(
    path: MentoringRoutes.sessions,
    builder: (context, state) => const MentoringScreen(),
    routes: [
      GoRoute(
        path: 'book',
        builder: (context, state) => const BookSessionScreen(),
      ),
      GoRoute(
        path: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(path: 'tasks', builder: (context, state) => const TasksScreen()),
      GoRoute(
        path: 'session/:id',
        builder: (context, state) => SessionDetailScreen(
          sessionId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
    ],
  ),
];
