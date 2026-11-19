import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/session_events.dart';
import '../../../../core/storage/providers.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/auth_session.dart';
import 'auth_providers.dart';

/// Estado de la sesión: `null` = sin sesión; cargando = restaurando al abrir la app.
class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    // Un 401 en cualquier petición (token vencido o cuenta deshabilitada) cierra la sesión.
    final expired = ref
        .read(sessionEventsProvider)
        .onExpired
        .listen((_) => logout());
    ref.onDispose(expired.cancel);
    final result = await ref.read(restoreSessionUseCaseProvider)();
    // Si no se pudo restaurar (p. ej. sin red) se muestra el login; el token se
    // conserva y se reintenta en la próxima apertura.
    return result.valueOrNull;
  }

  /// Devuelve `null` si entró, o el [Failure] para mostrarlo en el formulario.
  Future<Failure?> login(String email, String password) async {
    final result = await ref.read(loginUseCaseProvider)(email, password);
    return _apply(result);
  }

  Future<Failure?> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final result = await ref.read(registerUseCaseProvider)(
      fullName: fullName,
      email: email,
      password: password,
    );
    return _apply(result);
  }

  /// Cambia la contraseña y se queda con la sesión nueva (la anterior ya no vale).
  /// Devuelve `null` si salió bien, o el [Failure] para mostrarlo en el formulario.
  Future<Failure?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final result = await ref.read(changePasswordUseCaseProvider)(
      currentPassword,
      newPassword,
    );
    return _apply(result);
  }

  /// Marca el tutorial como visto (o lo reinicia) y actualiza el usuario en sesión.
  /// Si falla se ignora: el tutorial volvería a salir en el próximo ingreso.
  Future<void> setTutorialCompleted(bool completed) async {
    final session = state.value;
    if (session == null) return;
    final result = await ref.read(setTutorialUseCaseProvider)(
      completed: completed,
    );
    if (result case Ok(:final value)) {
      state = AsyncData(
        AuthSession(accessToken: session.accessToken, user: value),
      );
    }
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider)();
    await ref.read(localDataCleanerProvider).clearUserData();
    state = const AsyncData(null);
  }

  Failure? _apply(Result<AuthSession> result) {
    switch (result) {
      case Ok(:final value):
        state = AsyncData(value);
        return null;
      case Err(:final failure):
        return failure;
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);
