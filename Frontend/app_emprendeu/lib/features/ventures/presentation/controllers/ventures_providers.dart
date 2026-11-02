import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../documents/index.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/entities/venture.dart';
import '../../domain/repositories/ventures_repository.dart';
import '../../domain/usecases/create_venture_usecase.dart';
import '../../domain/usecases/get_my_venture_usecase.dart';
import '../../domain/usecases/milestones_usecases.dart';
import '../../domain/usecases/update_venture_usecase.dart';

/// Contrato del repositorio; la implementación se inyecta en `app/providers.dart`.
final venturesRepositoryProvider = Provider<VenturesRepository>(
  (ref) =>
      throw UnimplementedError('venturesRepositoryProvider sin implementación'),
);

final getMyVentureUseCaseProvider = Provider(
  (ref) => GetMyVentureUseCase(ref.watch(venturesRepositoryProvider)),
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

/// Emprendimiento del usuario (`null` = todavía no registró ninguno).
final myVentureProvider = FutureProvider<Venture?>(
  (ref) async => (await ref.watch(getMyVentureUseCaseProvider)()).getOrThrow(),
);

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
