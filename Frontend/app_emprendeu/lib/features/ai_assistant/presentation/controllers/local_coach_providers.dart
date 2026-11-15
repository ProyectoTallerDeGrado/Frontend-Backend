import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/local_knowledge_status.dart';
import '../../domain/repositories/local_coach_repository.dart';
import '../../domain/repositories/local_knowledge_repository.dart';
import '../../domain/usecases/local_coach_usecases.dart';
import 'local_ai_providers.dart';
import 'own_documents_providers.dart';

/// Contratos del coach del celular; las implementaciones van en `app/providers.dart`.
final localKnowledgeRepositoryProvider = Provider<LocalKnowledgeRepository>(
  (ref) => throw UnimplementedError(
    'localKnowledgeRepositoryProvider sin implementación',
  ),
);

final localCoachRepositoryProvider = Provider<LocalCoachRepository>(
  (ref) => throw UnimplementedError(
    'localCoachRepositoryProvider sin implementación',
  ),
);

final askLocalCoachUseCaseProvider = Provider(
  (ref) => AskLocalCoachUseCase(
    ref.watch(localKnowledgeRepositoryProvider),
    ref.watch(localCoachRepositoryProvider),
    own: ref.watch(ownDocumentsRepositoryProvider),
    minScore: AppConfig.localAiMinSimilarity,
  ),
);

final loadLocalConversationUseCaseProvider = Provider(
  (ref) =>
      LoadLocalConversationUseCase(ref.watch(localCoachRepositoryProvider)),
);

final clearLocalConversationUseCaseProvider = Provider(
  (ref) =>
      ClearLocalConversationUseCase(ref.watch(localCoachRepositoryProvider)),
);

final getLocalKnowledgeStatusUseCaseProvider = Provider(
  (ref) => GetLocalKnowledgeStatusUseCase(
    ref.watch(localKnowledgeRepositoryProvider),
  ),
);

final syncLocalKnowledgeUseCaseProvider = Provider(
  (ref) =>
      SyncLocalKnowledgeUseCase(ref.watch(localKnowledgeRepositoryProvider)),
);

/// Documentos del CIE-U en el celular y si se están actualizando.
class LocalKnowledgeState {
  const LocalKnowledgeState({
    required this.status,
    this.syncing = false,
    this.done = 0,
    this.total = 0,
    this.error,
  });

  final LocalKnowledgeStatus status;
  final bool syncing;
  final int done;
  final int total;
  final String? error;

  LocalKnowledgeState copyWith({
    LocalKnowledgeStatus? status,
    bool? syncing,
    int? done,
    int? total,
    String? Function()? error,
  }) => LocalKnowledgeState(
    status: status ?? this.status,
    syncing: syncing ?? this.syncing,
    done: done ?? this.done,
    total: total ?? this.total,
    error: error != null ? error() : this.error,
  );
}

/// Sincroniza la base de conocimiento local. Vive toda la sesión de la app.
class LocalKnowledgeController extends AsyncNotifier<LocalKnowledgeState> {
  /// Cada cuánto se vuelve a preguntar al servidor si hay documentos nuevos.
  static const staleAfter = Duration(hours: 12);

  @override
  Future<LocalKnowledgeState> build() async => LocalKnowledgeState(
    status: (await ref.watch(
      getLocalKnowledgeStatusUseCaseProvider,
    )()).getOrThrow(),
  );

  Future<void> sync() async {
    final current = await future;
    if (current.syncing || !ref.read(localAiReadyProvider)) return;
    state = AsyncData(current.copyWith(syncing: true, error: () => null));
    final result = await ref.read(syncLocalKnowledgeUseCaseProvider)(
      onProgress: (done, total) {
        final now = state.value;
        if (now != null) {
          state = AsyncData(now.copyWith(done: done, total: total));
        }
      },
    );
    final after = state.value ?? current;
    state = AsyncData(switch (result) {
      Ok(:final value) => after.copyWith(status: value, syncing: false),
      Err(:final failure) => after.copyWith(
        syncing: false,
        error: () => failure.message,
      ),
    });
  }

  /// Sincroniza si nunca se hizo, si pasó [staleAfter] o si aún no hay ningún
  /// documento (el CIE-U puede cargarlos en cualquier momento); sin red, no molesta.
  Future<void> syncIfStale() async {
    final current = await future;
    final last = current.status.syncedAt;
    if (current.status.documents > 0 &&
        last != null &&
        DateTime.now().difference(last) < staleAfter) {
      return;
    }
    await sync();
  }
}

final localKnowledgeControllerProvider =
    AsyncNotifierProvider<LocalKnowledgeController, LocalKnowledgeState>(
      LocalKnowledgeController.new,
    );

/// Dónde responde el coach.
enum CoachMode {
  /// Con la IA descargada en el celular (sin internet; archivos privados).
  device,

  /// Con el servidor del CIE-U (requiere conexión).
  online,
}

/// Lo que eligió la persona; `null` = el modo por defecto.
class CoachModePreference extends Notifier<CoachMode?> {
  @override
  CoachMode? build() => null;

  void choose(CoachMode mode) => state = mode;
}

final coachModePreferenceProvider =
    NotifierProvider<CoachModePreference, CoachMode?>(CoachModePreference.new);

/// Modo efectivo: el celular por defecto si la IA está instalada; si no, en línea.
final coachModeProvider = Provider<CoachMode>((ref) {
  if (!ref.watch(localAiReadyProvider)) return CoachMode.online;
  return ref.watch(coachModePreferenceProvider) ?? CoachMode.device;
});
