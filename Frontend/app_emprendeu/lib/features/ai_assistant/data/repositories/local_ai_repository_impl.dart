import 'package:flutter_edge_ai/flutter_edge_ai.dart'
    show DownloadCancelledException;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/local_ai_progress.dart';
import '../../domain/entities/local_ai_status.dart';
import '../../domain/repositories/local_ai_repository.dart';
import '../datasources/local_ai_engine_data_source.dart';

class LocalAiRepositoryImpl implements LocalAiRepository {
  LocalAiRepositoryImpl(this._engine);

  final LocalAiEngineDataSource _engine;

  @override
  int get downloadBytes => _engine.chatModelBytes + _engine.embedderBytes;

  @override
  Future<Result<LocalAiStatus>> status() async {
    if (!_engine.isSupported) return const Ok(LocalAiStatus.unsupported);
    try {
      return Ok(
        await _engine.isInstalled()
            ? LocalAiStatus.installed
            : LocalAiStatus.notInstalled,
      );
    } on Object {
      // El motor nativo no cargó (p. ej. un emulador x86_64: LiteRT es solo arm64).
      return const Ok(LocalAiStatus.unsupported);
    }
  }

  @override
  Future<Result<void>> install({
    required void Function(LocalAiProgress progress) onProgress,
  }) async {
    try {
      await _engine.install(onProgress);
      return const Ok(null);
    } on DownloadCancelledException {
      return const Err(LocalAiCancelledFailure());
    } on Object catch (error) {
      return Err(_failureFor(error));
    }
  }

  @override
  void cancelInstall() => _engine.cancel();

  @override
  Future<Result<void>> remove() async {
    try {
      await _engine.remove();
      return const Ok(null);
    } on Object {
      return const Err(
        LocalAiFailure(
          'No se pudo eliminar la IA del celular. Intenta de nuevo.',
        ),
      );
    }
  }

  /// Traduce el error del paquete a un mensaje claro. Se mira el texto porque el
  /// paquete no distingue «sin espacio» con un tipo propio en todas las plataformas.
  static Failure _failureFor(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('space') || text.contains('enospc')) {
      return const LocalAiFailure(
        'No hay espacio suficiente en el celular. Libera espacio e intenta de nuevo.',
      );
    }
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('download')) {
      return const LocalAiFailure(
        'Se interrumpió la descarga. Revisa tu conexión e intenta de nuevo; '
        'continuará desde donde quedó.',
      );
    }
    return const LocalAiFailure();
  }
}
