import 'package:go_router/go_router.dart';

import 'screens/training_screen.dart';

abstract final class TrainingRoutes {
  static const list = '/training';
}

/// Capacitaciones del programa (se agregan en `app/router.dart`).
final List<RouteBase> trainingRoutes = [
  GoRoute(
    path: TrainingRoutes.list,
    builder: (context, state) => const TrainingScreen(),
  ),
];
