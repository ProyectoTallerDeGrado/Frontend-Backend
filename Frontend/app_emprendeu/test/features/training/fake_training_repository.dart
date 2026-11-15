import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/training/domain/entities/training.dart';
import 'package:app_emprendeu/features/training/domain/repositories/training_repository.dart';

/// Capacitaciones en memoria; `enroll` marca la capacitación como inscrita.
class FakeTrainingRepository implements TrainingRepository {
  FakeTrainingRepository({List<Training>? trainings})
    : trainings = trainings ?? [];

  List<Training> trainings;
  int enrollCalls = 0;

  int pageCalls = 0;

  @override
  Future<Result<TrainingPage>> getTrainings({int page = 1}) async {
    pageCalls++;
    final start = (page - 1) * trainingPageSize;
    final end = (start + trainingPageSize).clamp(0, trainings.length);
    return Result.ok(
      TrainingPage(
        items: start >= trainings.length ? [] : trainings.sublist(start, end),
        page: page,
        total: trainings.length,
      ),
    );
  }

  @override
  Future<Result<Training>> enroll(int trainingId) async {
    enrollCalls++;
    final i = trainings.indexWhere((t) => t.id == trainingId);
    final old = trainings[i];
    final updated = Training(
      id: old.id,
      title: old.title,
      status: old.status,
      enrolled: true,
    );
    trainings[i] = updated;
    return Result.ok(updated);
  }
}
