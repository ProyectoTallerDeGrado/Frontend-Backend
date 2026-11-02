import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/training_repository.dart';
import '../../domain/usecases/training_usecases.dart';

/// Contrato del repositorio; la implementación se inyecta en `app/providers.dart`.
final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) =>
      throw UnimplementedError('trainingRepositoryProvider sin implementación'),
);

final getPublishedTrainingsUseCaseProvider = Provider(
  (ref) => GetPublishedTrainingsUseCase(ref.watch(trainingRepositoryProvider)),
);
final enrollTrainingUseCaseProvider = Provider(
  (ref) => EnrollTrainingUseCase(ref.watch(trainingRepositoryProvider)),
);

final publishedTrainingsProvider = FutureProvider.autoDispose<List<Training>>(
  (ref) async =>
      (await ref.watch(getPublishedTrainingsUseCaseProvider)()).getOrThrow(),
);

/// Inscribirse a una capacitación. Devuelve el [Failure] o `null` si salió bien.
class TrainingController extends Notifier<void> {
  @override
  void build() {}

  Future<Failure?> enroll(int trainingId) async {
    final result = await ref.read(enrollTrainingUseCaseProvider)(trainingId);
    if (result is Ok) ref.invalidate(publishedTrainingsProvider);
    return result.failureOrNull;
  }
}

final trainingControllerProvider = NotifierProvider<TrainingController, void>(
  TrainingController.new,
);
