import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

/// Contrato de acceso a la autenticación (lo implementa la capa `data`).
abstract interface class AuthRepository {
  /// Inicia sesión en el servidor. No guarda nada.
  Future<Result<AuthSession>> login(String email, String password);

  /// Crea una cuenta de emprendedor.
  Future<Result<void>> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// Usuario dueño del token (`GET /auth/me`).
  Future<Result<AuthUser>> fetchCurrentUser(String token);

  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}
