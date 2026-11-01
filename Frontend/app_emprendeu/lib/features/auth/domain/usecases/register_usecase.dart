import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import 'login_usecase.dart';

/// Crea la cuenta y entra directamente con ella.
class RegisterUseCase {
  const RegisterUseCase(this._repository, this._login);

  final AuthRepository _repository;
  final LoginUseCase _login;

  Future<Result<AuthSession>> call({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final created = await _repository.register(
      fullName: fullName.trim(),
      email: email.trim(),
      password: password,
    );
    if (created case Err(:final failure)) return Result.err(failure);
    return _login(email, password);
  }
}
