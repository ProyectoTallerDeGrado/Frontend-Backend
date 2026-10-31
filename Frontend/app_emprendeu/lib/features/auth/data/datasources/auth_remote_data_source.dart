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

  Future<AuthUserDto> me(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return AuthUserDto.fromJson(response.data!);
  }
}
