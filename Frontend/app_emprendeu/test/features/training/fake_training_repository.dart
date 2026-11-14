import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/training/domain/entities/training.dart';
import 'package:app_emprendeu/features/training/domain/repositories/training_repository.dart';

/// Capacitaciones en memoria; `enroll` marca la capacitación como inscrita.
class FakeTrainingRepository implements TrainingRepository {
  FakeTrainingRepository({List<Training>? trainings})
    : trainings = trainings ?? [];

  List<Training> trainings;
  int enrollCalls = 0;

  @override
  Future<Result<List<Training>>> getTrainings() async =>
      Result.ok(List.of(trainings));

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
