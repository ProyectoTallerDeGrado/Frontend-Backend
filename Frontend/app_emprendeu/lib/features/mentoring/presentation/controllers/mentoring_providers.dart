import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/online_controller.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../ventures/index.dart';
import '../../domain/entities/commitment.dart';
import '../../domain/entities/progress_log.dart';
import '../../domain/repositories/mentoring_repository.dart';
import '../../domain/usecases/mentoring_usecases.dart';

/// Contrato del repositorio; la implementación se inyecta en `app/providers.dart`.
final mentoringRepositoryProvider = Provider<MentoringRepository>(
  (ref) => throw UnimplementedError(
    'mentoringRepositoryProvider sin implementación',
  ),
);

final getCommitmentsUseCaseProvider = Provider(
  (ref) => GetCommitmentsUseCase(ref.watch(mentoringRepositoryProvider)),
);
final setCommitmentDoneUseCaseProvider = Provider(
  (ref) => SetCommitmentDoneUseCase(ref.watch(mentoringRepositoryProvider)),
);
final getProgressLogsUseCaseProvider = Provider(
  (ref) => GetProgressLogsUseCase(ref.watch(mentoringRepositoryProvider)),
);
final logProgressUseCaseProvider = Provider(
  (ref) => LogProgressUseCase(ref.watch(mentoringRepositoryProvider)),
);
final getPendingCountUseCaseProvider = Provider(
  (ref) => GetPendingCountUseCase(ref.watch(mentoringRepositoryProvider)),
);
final syncPendingUseCaseProvider = Provider(
  (ref) => SyncPendingUseCase(ref.watch(mentoringRepositoryProvider)),
);

/// Cada cuánto se reintenta enviar lo pendiente mientras haya algo en la cola.
final syncRetryIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

// --- sincronización -------------------------------------------------------------

enum SyncPhase { idle, syncing, done }

class SyncState {
  const SyncState({
    this.pending = 0,
    this.phase = SyncPhase.idle,
    this.lastCount = 0,
  });

  /// Cambios guardados en el dispositivo y aún sin enviar.
  final int pending;
  final SyncPhase phase;

  /// Registros enviados en la última sincronización (para el aviso «Todo sincronizado»).
  final int lastCount;

  SyncState copyWith({int? pending, SyncPhase? phase, int? lastCount}) =>
      SyncState(
        pending: pending ?? this.pending,
        phase: phase ?? this.phase,
        lastCount: lastCount ?? this.lastCount,
      );
}

/// Lleva la cuenta de lo pendiente y lo envía cuando vuelve la red.
class SyncController extends Notifier<SyncState> {
  Timer? _retry;

  @override
  SyncState build() {
    // Al volver la conexión se envía lo pendiente.
    ref.listen(onlineProvider, (_, online) {
      if (online && state.pending > 0) {
        unawaited(sync());
      }
    });
    // Si el sistema dice «hay red» pero el servidor no responde, se reintenta cada tanto.
    _retry = Timer.periodic(ref.watch(syncRetryIntervalProvider), (_) {
      if (state.pending > 0 && state.phase != SyncPhase.syncing) {
        unawaited(sync());
      }
    });
    ref.onDispose(() => _retry?.cancel());
    unawaited(refreshPending());
    return const SyncState();
  }

  Future<void> refreshPending() async {
    final count = await ref.read(getPendingCountUseCaseProvider)();
    state = state.copyWith(pending: count);
  }

  Future<void> sync() async {
    if (state.phase == SyncPhase.syncing || state.pending == 0) return;
    state = state.copyWith(phase: SyncPhase.syncing);
    final result = await ref.read(syncPendingUseCaseProvider)();
    switch (result) {
      case Ok(:final value):
        ref.read(onlineProvider.notifier).markOnline();
        state = SyncState(
          pending: 0,
          phase: SyncPhase.done,
          lastCount: value.synced,
        );
        ref.invalidate(commitmentsProvider);
        ref.invalidate(progressLogsProvider);
        Timer(const Duration(milliseconds: 2400), () {
          if (ref.mounted && state.phase == SyncPhase.done) {
            state = state.copyWith(phase: SyncPhase.idle);
          }
        });
      case Err(:final failure):
        if (failure is NetworkFailure) {
          ref.read(onlineProvider.notifier).markOffline();
        }
        state = state.copyWith(phase: SyncPhase.idle);
        await refreshPending();
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

/// Un registro que quedó solo en el dispositivo indica que no hay conexión.
void _reportConnection(Ref ref, {required bool offline}) {
  final online = ref.read(onlineProvider.notifier);
  offline ? online.markOffline() : online.markOnline();
}

// --- compromisos -----------------------------------------------------------------

class CommitmentsController extends AsyncNotifier<List<Commitment>> {
  @override
  Future<List<Commitment>> build() async =>
      (await ref.watch(getCommitmentsUseCaseProvider)()).getOrThrow();

  /// Marca o desmarca un compromiso al instante y lo confirma con el servidor.
  /// Devuelve el [Failure] si no se pudo (y revierte el cambio).
  Future<Failure?> toggle(Commitment commitment) async {
    final current = state.value ?? const [];
    final next = !commitment.done;
    state = AsyncData([
      for (final c in current)
        c.id == commitment.id ? c.copyWith(done: next) : c,
    ]);
    final result = await ref.read(setCommitmentDoneUseCaseProvider)(
      commitment,
      next,
    );
    switch (result) {
      case Ok(:final value):
        state = AsyncData([
          for (final c in state.value ?? const <Commitment>[])
            c.id == value.id ? value : c,
        ]);
        _reportConnection(ref, offline: value.pendingSync);
        await ref.read(syncControllerProvider.notifier).refreshPending();
        return null;
      case Err(:final failure):
        state = AsyncData(current);
        return failure;
    }
    return null;
  }
}

final commitmentsProvider =
    AsyncNotifierProvider<CommitmentsController, List<Commitment>>(
      CommitmentsController.new,
    );

// --- avances -----------------------------------------------------------------------

/// Avances del emprendimiento activo (el elegido si el usuario tiene varios).
class ProgressLogsController extends AsyncNotifier<List<ProgressLog>> {
  @override
  Future<List<ProgressLog>> build() async {
    final ventureId = await ref.watch(currentVentureIdProvider.future);
    return (await ref.watch(getProgressLogsUseCaseProvider)(
      ventureId: ventureId,
    )).getOrThrow();
  }

  /// Registra un avance; sin red queda guardado en el dispositivo. Devuelve el [Failure] si no se pudo.
  Future<Failure?> add(String text) async {
    final ventureId = await ref.read(currentVentureIdProvider.future);
    final result = await ref.read(logProgressUseCaseProvider)(
      text,
      ventureId: ventureId,
    );
    switch (result) {
      case Ok(:final value):
        state = AsyncData([value, ...state.value ?? const <ProgressLog>[]]);
        _reportConnection(ref, offline: value.pendingSync);
        await ref.read(syncControllerProvider.notifier).refreshPending();
        return null;
      case Err(:final failure):
        return failure;
    }
    return null;
  }
}

final progressLogsProvider =
    AsyncNotifierProvider<ProgressLogsController, List<ProgressLog>>(
      ProgressLogsController.new,
    );
