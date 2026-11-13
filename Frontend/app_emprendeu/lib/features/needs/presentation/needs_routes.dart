import 'package:go_router/go_router.dart';

import 'screens/needs_screen.dart';
import 'screens/report_need_screen.dart';

abstract final class NeedsRoutes {
  static const list = '/venture/needs';
  static const report = '/venture/needs/report';
}

/// Necesidades y dificultades del emprendimiento (se agregan en `app/router.dart`).
final List<RouteBase> needsRoutes = [
  GoRoute(
    path: NeedsRoutes.list,
    builder: (context, state) => const NeedsScreen(),
    routes: [
      GoRoute(
        path: 'report',
        builder: (context, state) => const ReportNeedScreen(),
      ),
    ],
  ),
];
