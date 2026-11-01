import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Recupera la sesión guardada al abrir la app. `Ok(null)` = no hay sesión.
class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession?>> call() async {
    final token = await _repository.readToken();
    if (token == null) return const Result.ok(null);

    final result = await _repository.fetchCurrentUser(token);
    switch (result) {
      case Ok(:final value):
        if (!value.isEntrepreneur) {
          await _repository.clearToken();
          return const Result.ok(null);
        }
        return Result.ok(AuthSession(accessToken: token, user: value));
      case Err(:final failure):
        // Token vencido o cuenta deshabilitada: se descarta. Un fallo de red
        // conserva el token y se informa para reintentar.
        if (failure is UnauthorizedFailure ||
            failure is AccountDisabledFailure) {
          await _repository.clearToken();
          return const Result.ok(null);
        }
        return Result.err(failure);
    }
  }
}
