import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Cambia la contraseña y conserva la sesión: el servidor invalida los tokens
/// anteriores, así que el token nuevo se guarda antes de devolver el resultado
/// (si no, la siguiente petición saldría con un token que ya no vale).
class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call(
    String currentPassword,
    String newPassword,
  ) async {
    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (result case Ok(:final value)) {
      await _repository.saveToken(value.accessToken);
    }
    return result;
  }
}
