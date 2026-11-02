import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/training/domain/entities/training.dart';
import 'package:app_emprendeu/features/training/domain/repositories/training_repository.dart';

/// Capacitaciones en memoria.
class FakeTrainingRepository implements TrainingRepository {
  FakeTrainingRepository({List<Training>? trainings, this.enrollFailure})
    : trainings = trainings ?? [];

  final List<Training> trainings;
  Failure? enrollFailure;
  int enrollCalls = 0;
  int? lastEnrolledId;

  @override
  Future<Result<List<Training>>> getPublished() async =>
      Result.ok(List.of(trainings));

  @override
  Future<Result<void>> enroll(int trainingId) async {
    enrollCalls++;
    lastEnrolledId = trainingId;
    if (enrollFailure != null) return Result.err(enrollFailure!);
    final i = trainings.indexWhere((t) => t.id == trainingId);
    final old = trainings[i];
    trainings[i] = Training(
      id: old.id,
      title: old.title,
      description: old.description,
      date: old.date,
      modality: old.modality,
      type: old.type,
      state: old.state,
      enrolledCount: old.enrolledCount + 1,
      enrolled: true,
    );
    return const Result.ok(null);
  }
}
