import 'package:go_router/go_router.dart';

import 'screens/journey_screen.dart';

abstract final class GamificationRoutes {
  static const journey = '/journey';
}

/// Rutas de la feature (se agregan en `app/router.dart`).
final List<RouteBase> gamificationRoutes = [
  GoRoute(
    path: GamificationRoutes.journey,
    builder: (context, state) => const JourneyScreen(),
  ),
];
