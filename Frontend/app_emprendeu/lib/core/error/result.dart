import 'failure.dart';

/// Resultado de una operación: éxito con valor o [Failure].
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  /// Valor si fue éxito; `null` si fue error.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}

extension ResultUnwrap<T> on Result<T> {
  /// Valor del éxito; si fue error lanza el [Failure] (para `FutureProvider`/`AsyncNotifier`).
  T getOrThrow() => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>(:final failure) => throw failure,
  };
}
