import 'package:go_router/go_router.dart';

import 'screens/edit_venture_screen.dart';
import 'screens/milestones_screen.dart';

abstract final class VenturesRoutes {
  static const edit = '/venture/edit';
  static const milestones = '/venture/milestones';
}

/// Pantallas a pantalla completa del emprendimiento (se agregan en `app/router.dart`).
final List<RouteBase> venturesRoutes = [
  GoRoute(
    path: VenturesRoutes.edit,
    builder: (context, state) => const EditVentureScreen(),
  ),
  GoRoute(
    path: VenturesRoutes.milestones,
    builder: (context, state) => const MilestonesScreen(),
  ),
];
