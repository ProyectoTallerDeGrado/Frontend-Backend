import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call(String email, String password) async {
    final result = await _repository.login(email.trim(), password);
    if (result case Ok(:final value)) {
      // El token solo se guarda si la cuenta corresponde a esta app.
      if (!value.user.isEntrepreneur) {
        return const Result.err(WrongPlatformFailure());
      }
      await _repository.saveToken(value.accessToken);
    }
    return result;
  }
}
