import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/local_ai_progress.dart';
import '../entities/local_ai_status.dart';
import '../repositories/local_ai_repository.dart';

class GetLocalAiStatusUseCase {
  const GetLocalAiStatusUseCase(this._repository);

  final LocalAiRepository _repository;

  Future<Result<LocalAiStatus>> call() => _repository.status();
}

/// Descarga la IA local. No vuelve a descargar si ya está instalada.
class InstallLocalAiUseCase {
  const InstallLocalAiUseCase(this._repository);

  final LocalAiRepository _repository;

  Future<Result<void>> call({
    required void Function(LocalAiProgress progress) onProgress,
  }) async {
    final current = await _repository.status();
    switch (current) {
      case Ok(value: LocalAiStatus.installed):
        return const Ok(null);
      case Ok(value: LocalAiStatus.unsupported):
        return const Err(_unsupported);
      case Err(:final failure):
        return Err(failure);
      case Ok():
        return _repository.install(onProgress: onProgress);
    }
  }
}

class CancelLocalAiInstallUseCase {
  const CancelLocalAiInstallUseCase(this._repository);

  final LocalAiRepository _repository;

  void call() => _repository.cancelInstall();
}

class RemoveLocalAiUseCase {
  const RemoveLocalAiUseCase(this._repository);

  final LocalAiRepository _repository;

  Future<Result<void>> call() => _repository.remove();
}

const _unsupported = LocalAiFailure(
  'La IA en el celular aún no está disponible en este dispositivo.',
);
