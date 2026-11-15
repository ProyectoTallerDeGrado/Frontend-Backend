import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/local_data_cleaner.dart';
import '../../../../core/storage/providers.dart';
import '../../../documents/index.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/entities/venture.dart';
import '../../domain/repositories/ventures_repository.dart';
import '../../domain/usecases/create_venture_usecase.dart';
import '../../domain/usecases/get_my_ventures_usecase.dart';
import '../../domain/usecases/milestones_usecases.dart';
import '../../domain/usecases/update_venture_usecase.dart';

/// Contrato del repositorio; la implementación se inyecta en `app/providers.dart`.
final venturesRepositoryProvider = Provider<VenturesRepository>(
  (ref) =>
      throw UnimplementedError('venturesRepositoryProvider sin implementación'),
);

final getMyVenturesUseCaseProvider = Provider(
  (ref) => GetMyVenturesUseCase(ref.watch(venturesRepositoryProvider)),
);

final createVentureUseCaseProvider = Provider(
  (ref) => CreateVentureUseCase(ref.watch(venturesRepositoryProvider)),
);

final updateVentureUseCaseProvider = Provider(
  (ref) => UpdateVentureUseCase(ref.watch(venturesRepositoryProvider)),
);

final getMilestonesUseCaseProvider = Provider(
  (ref) => GetMilestonesUseCase(ref.watch(venturesRepositoryProvider)),
);

final createMilestoneUseCaseProvider = Provider(
  (ref) => CreateMilestoneUseCase(ref.watch(venturesRepositoryProvider)),
);

final completeMilestoneUseCaseProvider = Provider(
  (ref) => CompleteMilestoneUseCase(ref.watch(venturesRepositoryProvider)),
);

/// Emprendimientos del usuario: la coordinación puede sumarlo a varios equipos.
/// Para recargar los datos se invalida este provider (no `myVentureProvider`).
final myVenturesProvider = FutureProvider<List<Venture>>(
  (ref) async => (await ref.watch(getMyVenturesUseCaseProvider)()).getOrThrow(),
);

/// Emprendimiento elegido por el usuario cuando tiene varios (`null` = el primero).
///
/// La elección se guarda en el dispositivo (bajo el prefijo `user.`, así se borra
/// al cerrar sesión) para recordarla al reabrir la app. Si el emprendimiento
/// guardado ya no es del usuario, `myVentureProvider` usa el primero.
class SelectedVentureController extends Notifier<int?> {
  static const storageKey = '${userDataPrefix}ventures.selected';

  @override
  int? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final raw = await ref.read(keyValueStoreProvider).read(storageKey);
    final saved = int.tryParse(raw ?? '');
    // Si ya eligió mientras se leía, esa elección manda.
    if (saved != null && ref.mounted && state == null) state = saved;
  }

  void select(int ventureId) {
    state = ventureId;
    ref.read(keyValueStoreProvider).write(storageKey, '$ventureId');
  }
}

final selectedVentureIdProvider =
    NotifierProvider<SelectedVentureController, int?>(
      SelectedVentureController.new,
    );

/// Emprendimiento con el que trabaja la app (`null` = todavía no tiene ninguno).
///
/// Es el elegido en [selectedVentureIdProvider] o, si no eligió (o ya no es parte
/// de él), el primero. Inicio, Camino, Mentorías y Coach lo usan para saber a qué
/// emprendimiento se refieren sus llamadas.
final myVentureProvider = FutureProvider<Venture?>((ref) async {
  final ventures = await ref.watch(myVenturesProvider.future);
  if (ventures.isEmpty) return null;
  final selected = ref.watch(selectedVentureIdProvider);
  return ventures.firstWhere(
    (v) => v.id == selected,
    orElse: () => ventures.first,
  );
});

/// Hitos de un emprendimiento.
final milestonesProvider = FutureProvider.autoDispose
    .family<List<Milestone>, int>(
      (ref, ventureId) async =>
          (await ref.watch(getMilestonesUseCaseProvider)(ventureId))
              .getOrThrow(),
    );

/// Resultado de guardar un hito con evidencia opcional.
class MilestoneOutcome {
  const MilestoneOutcome({this.failure, this.evidenceFailure});

  /// El hito no se guardó.
  final Failure? failure;

  /// El hito sí se guardó, pero la evidencia no se pudo subir.
  final Failure? evidenceFailure;

  bool get saved => failure == null;
}

/// Acciones sobre hitos: crear (con evidencia), adjuntar evidencia y marcar cumplido.
class MilestonesController extends Notifier<void> {
  @override
  void build() {}

  Future<MilestoneOutcome> create({
    required int ventureId,
    required String title,
    String? description,
    PickedFile? file,
  }) async {
    final created = await ref.read(createMilestoneUseCaseProvider)(
      ventureId,
      title: title,
      description: description,
    );
    switch (created) {
      case Err(:final failure):
        return MilestoneOutcome(failure: failure);
      case Ok(:final value):
        ref.invalidate(milestonesProvider);
        if (file == null) return const MilestoneOutcome();
        final failure = await attach(
          ventureId: ventureId,
          milestoneId: value.id,
          file: file,
        );
        return MilestoneOutcome(evidenceFailure: failure);
    }
  }

  /// Sube [file] como evidencia del hito. Devuelve el fallo, o `null` si salió bien.
  Future<Failure?> attach({
    required int ventureId,
    required int milestoneId,
    required PickedFile file,
  }) async {
    final result = await ref.read(uploadEvidenceUseCaseProvider)(
      ventureId: ventureId,
      milestoneId: milestoneId,
      file: file,
    );
    ref.invalidate(ventureEvidenceProvider);
    return result.failureOrNull;
  }

  Future<Failure?> complete(int milestoneId) async {
    final result = await ref.read(completeMilestoneUseCaseProvider)(
      milestoneId,
    );
    if (result is Ok) ref.invalidate(milestonesProvider);
    return result.failureOrNull;
  }
}

final milestonesControllerProvider =
    NotifierProvider<MilestonesController, void>(MilestonesController.new);

/// Id del emprendimiento activo para las llamadas de otras features (Camino,
/// Mentorías, Coach). `null` si no tiene o no se pudo cargar: el backend usa
/// entonces el primero del usuario.
final currentVentureIdProvider = FutureProvider<int?>((ref) async {
  try {
    return (await ref.watch(myVentureProvider.future))?.id;
  } on Object {
    return null;
  }
});
