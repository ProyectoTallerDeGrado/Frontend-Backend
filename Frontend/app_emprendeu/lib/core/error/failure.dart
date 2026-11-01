/// Fallos que la capa `data` entrega al resto de la app (nunca excepciones de red).
sealed class Failure implements Exception {
  const Failure(this.message);

  /// Mensaje listo para mostrar al usuario.
  final String message;
}

/// Sin conexión, tiempo agotado o servidor inalcanzable.
final class NetworkFailure extends Failure {
  const NetworkFailure()
    : super('No se pudo conectar con el servidor. Revisa tu conexión.');
}

/// El servidor respondió 5xx.
final class ServerFailure extends Failure {
  const ServerFailure()
    : super('El servidor tuvo un problema. Intenta de nuevo en unos minutos.');
}

/// Token ausente, vencido o inválido.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Tu sesión venció. Ingresa de nuevo.');
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure() : super('Correo o contraseña incorrectos.');
}

final class AccountDisabledFailure extends Failure {
  const AccountDisabledFailure()
    : super('Tu cuenta está deshabilitada. Contacta al CIE-U.');
}

final class RateLimitedFailure extends Failure {
  RateLimitedFailure(int retryAfterSeconds)
    : super(
        'Demasiados intentos. Intenta de nuevo en '
        '${(retryAfterSeconds / 60).ceil().clamp(1, 999)} min.',
      );
}

/// El backend rechazó un campo concreto (`field` = nombre del campo del formulario).
final class FieldFailure extends Failure {
  const FieldFailure(this.field, super.message);

  final String field;
}

/// La cuenta existe pero no corresponde a esta app (p. ej. personal del panel web).
final class WrongPlatformFailure extends Failure {
  const WrongPlatformFailure()
    : super(
        'Esta cuenta es del panel web del CIE-U. Esta app es para emprendedores.',
      );
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocurrió un error inesperado.']);
}

/// El usuario aún no registró su emprendimiento (el backend responde `no_venture`).
final class NoVentureFailure extends Failure {
  const NoVentureFailure() : super('Primero registra tu emprendimiento.');
}
