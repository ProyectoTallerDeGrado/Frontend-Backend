import '../../../../core/error/result.dart';
import '../entities/training.dart';
import '../repositories/training_repository.dart';

class GetPublishedTrainingsUseCase {
  const GetPublishedTrainingsUseCase(this._repository);
  final TrainingRepository _repository;

  /// Primero las próximas (por fecha) y después las realizadas (la más reciente arriba).
  Future<Result<List<Training>>> call() async {
    final result = await _repository.getPublished();
    final list = result.valueOrNull;
    if (list == null) return result;
    final upcoming = [
      for (final t in list)
        if (!t.isDone) t,
    ]..sort(_byDate);
    final done = [
      for (final t in list)
        if (t.isDone) t,
    ]..sort((a, b) => _byDate(b, a));
    return Result.ok([...upcoming, ...done]);
  }

  static int _byDate(Training a, Training b) {
    final x = a.date;
    final y = b.date;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }
}

class EnrollTrainingUseCase {
  const EnrollTrainingUseCase(this._repository);
  final TrainingRepository _repository;

  Future<Result<void>> call(int trainingId) => _repository.enroll(trainingId);
}
