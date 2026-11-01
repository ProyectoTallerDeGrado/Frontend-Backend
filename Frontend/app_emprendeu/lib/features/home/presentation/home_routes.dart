import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';

abstract final class HomeRoutes {
  static const home = '/home';
}

/// Rutas de la feature (se agregan en `app/router.dart`).
final List<RouteBase> homeRoutes = [
  GoRoute(
    path: HomeRoutes.home,
    builder: (context, state) => const HomeScreen(),
  ),
];
