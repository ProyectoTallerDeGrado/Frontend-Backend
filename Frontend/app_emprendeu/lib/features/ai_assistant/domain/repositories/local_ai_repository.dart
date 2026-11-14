import '../../../../core/error/result.dart';
import '../entities/local_ai_progress.dart';
import '../entities/local_ai_status.dart';

/// IA que corre en el celular: descarga, consulta de estado y borrado de los modelos.
abstract interface class LocalAiRepository {
  /// Tamaño aproximado de todo lo que se descarga, en bytes.
  int get downloadBytes;

  Future<Result<LocalAiStatus>> status();

  /// Descarga e instala lo que falte. Si se cancela devuelve `LocalAiCancelledFailure`.
  Future<Result<void>> install({
    required void Function(LocalAiProgress progress) onProgress,
  });

  /// Pide detener la descarga en curso (si no hay ninguna, no hace nada).
  void cancelInstall();

  /// Borra los modelos del celular y libera el espacio.
  Future<Result<void>> remove();
}
