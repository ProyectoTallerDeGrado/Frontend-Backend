import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/network/api_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _error(int status, {String? code, Object? details}) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: request,
      statusCode: status,
      data: {
        'error': {'code': code, 'message': 'msg', 'details': details},
      },
    ),
  );
}

void main() {
  test('errores de conexión', () {
    final timeout = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionTimeout,
    );
    expect(mapDioException(timeout), isA<NetworkFailure>());
  });

  test('códigos del contrato del backend', () {
    expect(
      mapDioException(_error(401, code: 'invalid_credentials')),
      isA<InvalidCredentialsFailure>(),
    );
    expect(
      mapDioException(_error(403, code: 'account_disabled')),
      isA<AccountDisabledFailure>(),
    );
    expect(
      mapDioException(_error(401, code: 'unauthorized')),
      isA<UnauthorizedFailure>(),
    );
    final taken = mapDioException(_error(409, code: 'email_taken'));
    expect(taken, isA<FieldFailure>());
    expect((taken as FieldFailure).field, 'email');
    final name = mapDioException(_error(422, code: 'invalid_name'));
    expect((name as FieldFailure).field, 'name');
  });

  test('límite de intentos informa los minutos', () {
    final failure = mapDioException(
      _error(429, code: 'rate_limited', details: {'retry_after': 540}),
    );
    expect(failure, isA<RateLimitedFailure>());
    expect(failure.message, contains('9 min'));
  });

  test('5xx y respuestas desconocidas', () {
    expect(
      mapDioException(_error(500, code: 'internal_error')),
      isA<ServerFailure>(),
    );
    expect(
      mapDioException(_error(404, code: 'not_found')),
      isA<UnknownFailure>(),
    );
  });
}
