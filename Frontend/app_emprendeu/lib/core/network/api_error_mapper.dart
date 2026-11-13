import 'package:dio/dio.dart';

import '../error/failure.dart';

/// Traduce un [DioException] al [Failure] correspondiente según el contrato
/// de errores del backend: `{"error": {"code", "message", "details"}}`.
Failure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    default:
      break;
  }

  final status = e.response?.statusCode ?? 0;
  final data = e.response?.data;
  final error = data is Map ? data['error'] : null;
  final code = error is Map ? error['code'] as String? : null;
  final details = error is Map ? error['details'] : null;

  switch (code) {
    case 'invalid_credentials':
      return const InvalidCredentialsFailure();
    case 'account_disabled':
      return const AccountDisabledFailure();
    case 'unauthorized':
      return const UnauthorizedFailure();
    case 'slot_unavailable':
      return const SlotUnavailableFailure();
    case 'ai_unavailable':
      return const AssistantUnavailableFailure();
    case 'session_closed':
      return const SessionClosedFailure();
    case 'need_already_registered':
      return const NeedAlreadyRegisteredFailure();
    case 'wrong_password':
      // 400 (no 401): una clave actual equivocada no debe cerrar la sesión.
      return const FieldFailure(
        'currentPassword',
        'La contraseña actual no es correcta.',
      );
    case 'email_taken':
      return const FieldFailure(
        'email',
        'Ya existe una cuenta con ese correo.',
      );
    case 'invalid_name':
      return const FieldFailure('name', 'Ingresa nombre y apellido.');
    case 'rate_limited':
      final retry = details is Map ? details['retry_after'] : null;
      return RateLimitedFailure(retry is num ? retry.toInt() : 60);
  }

  if (status == 401) return const UnauthorizedFailure();
  if (status >= 500) return const ServerFailure();
  if (status == 0) return const NetworkFailure();
  final message = error is Map ? error['message'] as String? : null;
  return UnknownFailure(message ?? 'No se pudo completar la operación.');
}
