import 'package:dio/dio.dart';

import '../models/auth_user_dto.dart';
import '../models/login_response_dto.dart';

/// Llamadas HTTP de autenticación. Lanza [DioException]; el repositorio las mapea.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LoginResponseDto> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return LoginResponseDto.fromJson(response.data!);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _dio.post<void>(
      '/auth/register',
      data: {'nombre_completo': fullName, 'email': email, 'password': password},
    );
  }

  Future<LoginResponseDto> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/change-password',
      data: {'password_actual': currentPassword, 'password_nueva': newPassword},
    );
    return LoginResponseDto.fromJson(response.data!);
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio.post<void>('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      '/auth/reset-password',
      data: {'email': email, 'codigo': code, 'password_nueva': newPassword},
    );
  }

  /// Marca (`POST`) o reinicia (`DELETE`) el tutorial guiado del usuario actual.
  Future<AuthUserDto> setTutorial({required bool completed}) async {
    final response = completed
        ? await _dio.post<Map<String, dynamic>>('/auth/me/tutorial')
        : await _dio.delete<Map<String, dynamic>>('/auth/me/tutorial');
    return AuthUserDto.fromJson(response.data!);
  }

  Future<AuthUserDto> me(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return AuthUserDto.fromJson(response.data!);
  }
}
