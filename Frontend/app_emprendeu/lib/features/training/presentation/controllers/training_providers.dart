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

/// Lo que muestra la lista: lo cargado hasta ahora y si faltan páginas.
class TrainingList {
  const TrainingList({
    required this.items,
    required this.page,
    required this.total,
  });

  final List<Training> items;
  final int page;
  final int total;

  /// Hay más capacitaciones en el servidor que las cargadas.
  bool get hasMore => page * trainingPageSize < total;

  TrainingList copyWith({List<Training>? items, int? page}) => TrainingList(
    items: items ?? this.items,
    page: page ?? this.page,
    total: total,
  );
}

/// Capacitaciones del programa con la inscripción y asistencia propias,
/// paginadas: «Cargar más» suma la página siguiente.
class TrainingsController extends AsyncNotifier<TrainingList> {
  @override
  Future<TrainingList> build() async {
    final first = (await ref.watch(getTrainingsUseCaseProvider)()).getOrThrow();
    return TrainingList(items: first.items, page: 1, total: first.total);
  }

  /// Pide la página siguiente. Devuelve `null` si salió bien o el [Failure].
  Future<Failure?> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return null;
    final result = await ref.read(getTrainingsUseCaseProvider)(
      page: current.page + 1,
    );
    switch (result) {
      case Ok(:final value):
        state = AsyncData(
          current.copyWith(
            items: [...current.items, ...value.items],
            page: value.page,
          ),
        );
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  /// Inscribirse. Reemplaza la capacitación en la lista sin perder las páginas
  /// ya cargadas. Devuelve `null` si salió bien o el [Failure].
  Future<Failure?> enroll(int trainingId) async {
    final result = await ref.read(enrollInTrainingUseCaseProvider)(trainingId);
    switch (result) {
      case Ok(:final value):
        final current = state.value;
        if (current != null) {
          state = AsyncData(
            current.copyWith(
              items: [
                for (final t in current.items) t.id == trainingId ? value : t,
              ],
            ),
          );
        }
        return null;
      case Err(:final failure):
        return failure;
    }
    return null;
  }
}

final trainingsProvider =
    AsyncNotifierProvider.autoDispose<TrainingsController, TrainingList>(
      TrainingsController.new,
    );
