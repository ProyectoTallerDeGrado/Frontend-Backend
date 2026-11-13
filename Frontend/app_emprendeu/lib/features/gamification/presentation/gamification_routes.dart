import 'package:go_router/go_router.dart';

import 'screens/journey_screen.dart';
import 'screens/xp_badges_screen.dart';

abstract final class GamificationRoutes {
  static const journey = '/journey';
  static const xp = '/xp';
}

/// Rutas de la feature dentro de la barra inferior (se agregan en `app/router.dart`).
final List<RouteBase> gamificationRoutes = [
  GoRoute(
    path: GamificationRoutes.journey,
    builder: (context, state) => const JourneyScreen(),
  ),
];

/// Pantallas a pantalla completa, fuera de la barra inferior.
final List<RouteBase> gamificationDetailRoutes = [
  GoRoute(
    path: GamificationRoutes.xp,
    builder: (context, state) => const XpBadgesScreen(),
  ),
];
