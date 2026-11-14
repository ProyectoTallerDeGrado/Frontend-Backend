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

final getTrainingsUseCaseProvider = Provider(
  (ref) => GetTrainingsUseCase(ref.watch(trainingRepositoryProvider)),
);
final enrollInTrainingUseCaseProvider = Provider(
  (ref) => EnrollInTrainingUseCase(ref.watch(trainingRepositoryProvider)),
);

/// Capacitaciones del programa con la inscripción y asistencia propias.
final trainingsProvider = FutureProvider.autoDispose<List<Training>>(
  (ref) async => (await ref.watch(getTrainingsUseCaseProvider)()).getOrThrow(),
);

/// Inscribirse en una capacitación. Devuelve `null` si salió bien o el [Failure].
class TrainingController extends Notifier<void> {
  @override
  void build() {}

  Future<Failure?> enroll(int trainingId) async {
    final result = await ref.read(enrollInTrainingUseCaseProvider)(trainingId);
    switch (result) {
      case Ok():
        ref.invalidate(trainingsProvider);
        return null;
      case Err(:final failure):
        return failure;
    }
  }
}

final trainingControllerProvider = NotifierProvider<TrainingController, void>(
  TrainingController.new,
);
