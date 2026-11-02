import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/auth/domain/entities/auth_session.dart';
import 'package:app_emprendeu/features/auth/domain/entities/auth_user.dart';
import 'package:app_emprendeu/features/auth/domain/repositories/auth_repository.dart';

const entrepreneur = AuthUser(
  id: 7,
  nombre: 'Camila',
  apellido: 'Justiniano',
  email: 'camila@correo.com',
  rol: 'emprendedor',
);

const staffUser = AuthUser(
  id: 1,
  nombre: 'Jhonny',
  apellido: 'Roca',
  email: 'jroca@uagrm.edu.bo',
  rol: 'administrador',
);

/// Repositorio en memoria para pruebas: configurable y sin red.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginResult,
    this.registerResult = const Result.ok(null),
    this.meResult,
    this.token,
    this.changePasswordResult,
  });

  Result<AuthSession>? loginResult;
  Result<void> registerResult;
  Result<AuthUser>? meResult;
  String? token;
  Result<AuthSession>? changePasswordResult;

  int loginCalls = 0;
  int registerCalls = 0;
  int changePasswordCalls = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;

  @override
  Future<Result<AuthSession>> login(String email, String password) async {
    loginCalls++;
    return loginResult ??
        const Result.ok(
          AuthSession(accessToken: 'tok-123', user: entrepreneur),
        );
  }

  @override
  Future<Result<void>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    return registerResult;
  }

  @override
  Future<Result<AuthSession>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    return changePasswordResult ??
        const Result.ok(
          AuthSession(accessToken: 'tok-nuevo', user: entrepreneur),
        );
  }

  @override
  Future<Result<AuthUser>> fetchCurrentUser(String token) async =>
      meResult ?? const Result.ok(entrepreneur);

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> clearToken() async => token = null;
}

Failure failureOf(Result<Object?> r) => r.failureOrNull!;

/// Repositorio con una sesión ya guardada (se abre directo la app).
class FakeAuthRepositoryWithToken extends FakeAuthRepository {
  FakeAuthRepositoryWithToken() : super(token: 'tok-1');
}
