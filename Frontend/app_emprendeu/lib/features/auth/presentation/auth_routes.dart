import 'package:go_router/go_router.dart';

import 'screens/account_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';

/// Rutas de la feature (se agregan en `app/router.dart`).
abstract final class AuthRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const account = '/account';
  static const changePassword = '/account/password';
}

final List<RouteBase> authRoutes = [
  GoRoute(
    path: AuthRoutes.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: AuthRoutes.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: AuthRoutes.register,
    builder: (context, state) => const RegisterScreen(),
  ),
];

/// Pestaña «Perfil» (cuenta y cierre de sesión): la monta el shell de navegación.
final List<RouteBase> accountRoutes = [
  GoRoute(
    path: AuthRoutes.account,
    builder: (context, state) => const AccountScreen(),
    routes: [
      GoRoute(
        path: 'password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],
  ),
];
