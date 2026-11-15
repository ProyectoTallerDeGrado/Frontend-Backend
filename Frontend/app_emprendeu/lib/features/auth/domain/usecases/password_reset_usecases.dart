import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Tamaño del código que llega por correo.
const resetCodeLength = 6;

/// Pide el código de recuperación (CU01).
class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String email) =>
      _repository.requestPasswordReset(email.trim());
}

/// Cambia la contraseña con el código. Valida el código antes de llamar al servidor.
class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String code,
    required String newPassword,
  }) {
    final digits = code.trim();
    if (!RegExp('^\\d{$resetCodeLength}\$').hasMatch(digits)) {
      return Future.value(
        const Result.err(
          FieldFailure('code', 'El código tiene $resetCodeLength dígitos.'),
        ),
      );
    }
    return _repository.resetPassword(
      email: email.trim(),
      code: digits,
      newPassword: newPassword,
    );
  }
}
