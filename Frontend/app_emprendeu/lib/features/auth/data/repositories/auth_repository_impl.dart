import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._local);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e) {
      return Result.err(mapDioException(e));
    } on FormatException {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> login(String email, String password) =>
      _guard(() async => (await _remote.login(email, password)).toEntity());

  @override
  Future<Result<void>> register({
    required String fullName,
    required String email,
    required String password,
  }) => _guard(
    () =>
        _remote.register(fullName: fullName, email: email, password: password),
  );

  @override
  Future<Result<AuthSession>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(
    () async => (await _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    )).toEntity(),
  );

  @override
  Future<Result<AuthUser>> fetchCurrentUser(String token) =>
      _guard(() async => (await _remote.me(token)).toEntity());

  @override
  Future<String?> readToken() => _local.readToken();

  @override
  Future<void> saveToken(String token) => _local.saveToken(token);

  @override
  Future<void> clearToken() => _local.clearToken();
}
