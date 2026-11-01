import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'session_events.dart';

/// Añade el token a cada petición y avisa si el servidor responde 401 estando
/// autenticados (token vencido o cuenta deshabilitada).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens, this._events);

  final TokenStorage _tokens;
  final SessionEvents _events;

  static const _publicPaths = ['/auth/login', '/auth/register'];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final explicit = options.headers.containsKey('Authorization');
    if (!explicit && !_publicPaths.contains(options.path)) {
      final token = await _tokens.read();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    if (status == 401 && !_publicPaths.contains(path)) {
      _events.notifyExpired();
    }
    handler.next(err);
  }
}
