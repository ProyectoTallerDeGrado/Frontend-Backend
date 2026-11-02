import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_assistant/index.dart';
import '../features/auth/index.dart';
import '../features/documents/index.dart';
import '../features/gamification/index.dart';
import '../features/home/index.dart';
import '../features/mentoring/index.dart';
import '../features/training/index.dart';
import '../features/ventures/index.dart';
import '../shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Avisa al router cuando se abre o se cierra la sesión para que reevalúe
  // `redirect`. No con cada cambio del estado: renovar el token (cambio de
  // contraseña) no es navegar, y un refresco reabriría la ruta actual.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (previous, next) {
    final changed =
        previous?.isLoading != next.isLoading ||
        (previous?.value == null) != (next.value == null);
    if (changed) refresh.value++;
  });

  final router = GoRouter(
    initialLocation: AuthRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      if (auth.isLoading) {
        return location == AuthRoutes.splash ? null : AuthRoutes.splash;
      }
      final isPublic =
          location == AuthRoutes.login || location == AuthRoutes.register;
      if (auth.value == null) return isPublic ? null : AuthRoutes.login;
      return (isPublic || location == AuthRoutes.splash)
          ? HomeRoutes.home
          : null;
    },
    routes: [
      ...authRoutes,
      ...venturesRoutes,
      ...documentsRoutes,
      ...trainingRoutes,
      // Pantallas con sesión: barra inferior Inicio · Camino · Mentorías · Perfil.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: homeRoutes),
          StatefulShellBranch(routes: gamificationRoutes),
          StatefulShellBranch(routes: mentoringRoutes),
          StatefulShellBranch(routes: assistantRoutes),
          StatefulShellBranch(routes: accountRoutes),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
