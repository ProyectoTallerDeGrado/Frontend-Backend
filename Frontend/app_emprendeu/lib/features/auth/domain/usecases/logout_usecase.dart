import '../repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  /// El JWT no tiene estado en el servidor: cerrar sesión es descartarlo.
  Future<void> call() => _repository.clearToken();
}
