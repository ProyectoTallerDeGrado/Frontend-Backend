import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/index.dart';
import '../features/gamification/index.dart';
import '../features/home/index.dart';
import '../shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Avisa al router cuando cambia la sesión para que reevalúe `redirect`.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);

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
      // Pantallas con sesión: barra inferior Inicio · Camino · Perfil.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: homeRoutes),
          StatefulShellBranch(routes: gamificationRoutes),
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
