import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/local_ai_progress.dart';
import '../../domain/entities/local_ai_status.dart';
import '../../domain/repositories/local_ai_repository.dart';
import '../../domain/usecases/local_ai_usecases.dart';
import 'local_coach_providers.dart';

/// Contrato de la IA local; la implementación se inyecta en `app/providers.dart`.
final localAiRepositoryProvider = Provider<LocalAiRepository>(
  (ref) =>
      throw UnimplementedError('localAiRepositoryProvider sin implementación'),
);

final getLocalAiStatusUseCaseProvider = Provider(
  (ref) => GetLocalAiStatusUseCase(ref.watch(localAiRepositoryProvider)),
);

final installLocalAiUseCaseProvider = Provider(
  (ref) => InstallLocalAiUseCase(ref.watch(localAiRepositoryProvider)),
);

final cancelLocalAiInstallUseCaseProvider = Provider(
  (ref) => CancelLocalAiInstallUseCase(ref.watch(localAiRepositoryProvider)),
);

final removeLocalAiUseCaseProvider = Provider(
  (ref) => RemoveLocalAiUseCase(ref.watch(localAiRepositoryProvider)),
);

/// Estado de la tarjeta «IA en tu celular».
class LocalAiState {
  const LocalAiState({
    required this.status,
    required this.downloadBytes,
    this.progress,
    this.busy = false,
    this.error,
  });

  final LocalAiStatus status;
  final int downloadBytes;

  /// Avance de la descarga en curso; `null` si no se está descargando.
  final LocalAiProgress? progress;

  /// Se está eliminando (o preparando) la IA.
  final bool busy;

  /// Mensaje del último fallo, para mostrarlo bajo los botones.
  final String? error;

  bool get downloading => progress != null;

  LocalAiState copyWith({
    LocalAiStatus? status,
    LocalAiProgress? Function()? progress,
    bool? busy,
    String? Function()? error,
  }) => LocalAiState(
    status: status ?? this.status,
    downloadBytes: downloadBytes,
    progress: progress != null ? progress() : this.progress,
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
  );
}

/// Descarga, cancela y elimina la IA local. No se descarta al salir de Perfil:
/// la descarga sigue mientras la app esté abierta.
class LocalAiController extends AsyncNotifier<LocalAiState> {
  @override
  Future<LocalAiState> build() async {
    final status = (await ref.watch(
      getLocalAiStatusUseCaseProvider,
    )()).getOrThrow();
    return LocalAiState(
      status: status,
      downloadBytes: ref.watch(localAiRepositoryProvider).downloadBytes,
    );
  }

  Future<void> download() async {
    final current = state.value;
    if (current == null || current.downloading || current.busy) return;
    state = AsyncData(
      current.copyWith(
        progress: () =>
            const LocalAiProgress(step: LocalAiStep.embedder, percent: 0),
        error: () => null,
      ),
    );
    final result = await ref.read(installLocalAiUseCaseProvider)(
      onProgress: (p) {
        final now = state.value;
        // Ignora avances tardíos si ya se canceló o terminó.
        if (now == null || !now.downloading) return;
        state = AsyncData(now.copyWith(progress: () => p));
      },
    );
    final after = state.value ?? current;
    state = AsyncData(switch (result) {
      Ok() => after.copyWith(
        status: LocalAiStatus.installed,
        progress: () => null,
      ),
      Err(failure: LocalAiCancelledFailure()) => after.copyWith(
        progress: () => null,
      ),
      Err(:final failure) => after.copyWith(
        progress: () => null,
        error: () => failure.message,
      ),
    });
    // Recién instalada: se traen los documentos del CIE-U para usarla ya.
    if (result is Ok) {
      await ref.read(localKnowledgeControllerProvider.notifier).sync();
    }
  }

  void cancel() => ref.read(cancelLocalAiInstallUseCaseProvider)();

  Future<void> remove() async {
    final current = state.value;
    if (current == null || current.downloading || current.busy) return;
    state = AsyncData(current.copyWith(busy: true, error: () => null));
    final result = await ref.read(removeLocalAiUseCaseProvider)();
    state = AsyncData(switch (result) {
      Ok() => current.copyWith(status: LocalAiStatus.notInstalled, busy: false),
      Err(:final failure) => current.copyWith(
        busy: false,
        error: () => failure.message,
      ),
    });
  }
}

final localAiControllerProvider =
    AsyncNotifierProvider<LocalAiController, LocalAiState>(
      LocalAiController.new,
    );

/// `true` si la IA local está lista para usarse (la leerá el Coach).
final localAiReadyProvider = Provider<bool>(
  (ref) =>
      ref.watch(localAiControllerProvider).value?.status ==
      LocalAiStatus.installed,
);

/// Formato corto de un tamaño en bytes: «2,8 GB», «165 MB».
String formatBytes(int bytes) {
  const gb = 1024 * 1024 * 1024;
  const mb = 1024 * 1024;
  if (bytes >= gb) {
    return '${(bytes / gb).toStringAsFixed(1).replaceAll('.', ',')} GB';
  }
  return '${(bytes / mb).round()} MB';
}

/// Mensaje de un error de carga del estado (para el `AsyncValue.error`).
String localAiErrorText(Object error) =>
    error is Failure ? error.message : 'No se pudo revisar la IA del celular.';
