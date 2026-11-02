import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/auth/domain/entities/auth_session.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/login_usecase.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/register_usecase.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_auth_repository.dart';

void main() {
  group('LoginUseCase', () {
    test('guarda el token solo si la cuenta es de emprendedor', () async {
      final repo = FakeAuthRepository();
      final result = await LoginUseCase(repo)(' camila@correo.com ', 'x');
      expect(result, isA<Ok<AuthSession>>());
      expect(repo.token, 'tok-123');
    });

    test('rechaza cuentas del panel web y no guarda el token', () async {
      final repo = FakeAuthRepository(
        loginResult: const Result.ok(
          AuthSession(accessToken: 'tok-staff', user: staffUser),
        ),
      );
      final result = await LoginUseCase(repo)('a@b.co', 'x');
      expect(failureOf(result), isA<WrongPlatformFailure>());
      expect(repo.token, isNull);
    });

    test('propaga el fallo del servidor sin guardar nada', () async {
      final repo = FakeAuthRepository(
        loginResult: const Result.err(InvalidCredentialsFailure()),
      );
      final result = await LoginUseCase(repo)('a@b.co', 'mala');
      expect(failureOf(result), isA<InvalidCredentialsFailure>());
      expect(repo.token, isNull);
    });
  });

  group('ChangePasswordUseCase', () {
    test(
      'guarda el token nuevo: el anterior ya no vale en el servidor',
      () async {
        final repo = FakeAuthRepository(token: 'tok-viejo');
        final result = await ChangePasswordUseCase(repo)(
          'actual-123',
          'nueva-4567',
        );
        expect(result, isA<Ok<AuthSession>>());
        expect(repo.token, 'tok-nuevo');
        expect(repo.lastCurrentPassword, 'actual-123');
        expect(repo.lastNewPassword, 'nueva-4567');
      },
    );

    test('si falla conserva el token y propaga el fallo', () async {
      final repo = FakeAuthRepository(
        token: 'tok-viejo',
        changePasswordResult: const Result.err(
          FieldFailure(
            'currentPassword',
            'La contraseña actual no es correcta.',
          ),
        ),
      );
      final result = await ChangePasswordUseCase(repo)('mala', 'nueva-4567');
      expect(failureOf(result), isA<FieldFailure>());
      expect(repo.token, 'tok-viejo');
    });
  });

  group('RegisterUseCase', () {
    test('crea la cuenta y entra con ella', () async {
      final repo = FakeAuthRepository();
      final result = await RegisterUseCase(repo, LoginUseCase(repo))(
        fullName: ' Camila Justiniano ',
        email: 'camila@correo.com',
        password: 'clave-larga-1',
      );
      expect(result, isA<Ok<AuthSession>>());
      expect(repo.registerCalls, 1);
      expect(repo.loginCalls, 1);
      expect(repo.token, 'tok-123');
    });

    test('si el registro falla no intenta entrar', () async {
      final repo = FakeAuthRepository(
        registerResult: const Result.err(FieldFailure('email', 'Ya existe')),
      );
      final result = await RegisterUseCase(repo, LoginUseCase(repo))(
        fullName: 'Camila Justiniano',
        email: 'camila@correo.com',
        password: 'clave-larga-1',
      );
      expect(failureOf(result), isA<FieldFailure>());
      expect(repo.loginCalls, 0);
    });
  });

  group('RestoreSessionUseCase', () {
    test('sin token no hay sesión', () async {
      final result = await RestoreSessionUseCase(FakeAuthRepository())();
      expect(result.valueOrNull, isNull);
      expect(result, isA<Ok<AuthSession?>>());
    });

    test('con token válido recupera al usuario', () async {
      final repo = FakeAuthRepository(token: 'tok-1');
      final result = await RestoreSessionUseCase(repo)();
      expect(result.valueOrNull?.user.nombre, 'Camila');
      expect(result.valueOrNull?.accessToken, 'tok-1');
    });

    test('token vencido se descarta', () async {
      final repo = FakeAuthRepository(
        token: 'viejo',
        meResult: const Result.err(UnauthorizedFailure()),
      );
      final result = await RestoreSessionUseCase(repo)();
      expect(result.valueOrNull, isNull);
      expect(repo.token, isNull);
    });

    test('sin red conserva el token y avisa del fallo', () async {
      final repo = FakeAuthRepository(
        token: 'tok-1',
        meResult: const Result.err(NetworkFailure()),
      );
      final result = await RestoreSessionUseCase(repo)();
      expect(failureOf(result), isA<NetworkFailure>());
      expect(repo.token, 'tok-1');
    });

    test('una cuenta de personal se descarta', () async {
      final repo = FakeAuthRepository(
        token: 'tok-staff',
        meResult: const Result.ok(staffUser),
      );
      final result = await RestoreSessionUseCase(repo)();
      expect(result.valueOrNull, isNull);
      expect(repo.token, isNull);
    });
  });
}
