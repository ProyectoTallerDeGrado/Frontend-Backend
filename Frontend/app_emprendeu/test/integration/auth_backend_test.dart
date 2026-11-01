@Tags(['integration'])
library;

import 'dart:io';

import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/network/dio_client.dart';
import 'package:app_emprendeu/core/storage/token_storage.dart';
import 'package:app_emprendeu/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:app_emprendeu/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app_emprendeu/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/login_usecase.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/register_usecase.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Memoria en lugar del almacén seguro del sistema.
class _MemoryStorage implements TokenStorage {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async => token = value;
  @override
  Future<void> clear() async => token = null;
}

/// Prueba la capa de datos real contra un backend en marcha:
///
///     API_BASE_URL=http://localhost:8000/api/v1 \
///     flutter test --tags integration test/integration
///
/// Opcional: `STAFF_EMAIL` y `STAFF_PASSWORD` (cuenta de personal) para probar
/// el rechazo de cuentas del panel web.
void main() {
  final baseUrl = Platform.environment['API_BASE_URL'];
  final skip = baseUrl == null ? 'Define API_BASE_URL para correrla' : null;

  late _MemoryStorage storage;
  late AuthRepositoryImpl repository;

  setUp(() {
    storage = _MemoryStorage();
    repository = AuthRepositoryImpl(
      AuthRemoteDataSource(createDio(baseUrl: baseUrl ?? 'http://localhost')),
      AuthLocalDataSource(storage),
    );
  });

  test('registro, sesión restaurada y errores reales', skip: skip, () async {
    final email = 'it-${DateTime.now().microsecondsSinceEpoch}@correo.com';
    final login = LoginUseCase(repository);

    final session = await RegisterUseCase(repository, login)(
      fullName: 'Camila Integracion',
      email: email,
      password: 'clave-larga-1',
    );
    expect(session.valueOrNull?.user.isEntrepreneur, isTrue);
    expect(storage.token, isNotNull);

    final restored = await RestoreSessionUseCase(repository)();
    expect(restored.valueOrNull?.user.email, email);

    // correo repetido
    final again = await RegisterUseCase(repository, login)(
      fullName: 'Camila Integracion',
      email: email,
      password: 'clave-larga-1',
    );
    expect(again.failureOrNull, isA<FieldFailure>());

    // clave incorrecta
    storage.token = null;
    final wrong = await login(email, 'incorrecta-1');
    expect(wrong.failureOrNull, isA<InvalidCredentialsFailure>());
    expect(storage.token, isNull);

    // token inválido guardado: se descarta
    storage.token = 'no.es.un.token';
    final invalid = await RestoreSessionUseCase(repository)();
    expect(invalid.valueOrNull, isNull);
    expect(storage.token, isNull);
  });

  test('una cuenta de personal no entra a la app', skip: skip, () async {
    final email = Platform.environment['STAFF_EMAIL'];
    final password = Platform.environment['STAFF_PASSWORD'];
    if (email == null || password == null) {
      markTestSkipped('Define STAFF_EMAIL y STAFF_PASSWORD');
      return;
    }
    final result = await LoginUseCase(repository)(email, password);
    expect(result.failureOrNull, isA<WrongPlatformFailure>());
    expect(storage.token, isNull);
  });

  test('sin servidor devuelve NetworkFailure', () async {
    final offline = AuthRepositoryImpl(
      AuthRemoteDataSource(createDio(baseUrl: 'http://127.0.0.1:9')),
      AuthLocalDataSource(_MemoryStorage()),
    );
    final result = await LoginUseCase(offline)('a@b.co', 'x');
    expect(result.failureOrNull, isA<NetworkFailure>());
  });
}
