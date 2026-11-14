import '../../../../core/error/result.dart';
import '../entities/training.dart';
import '../repositories/training_repository.dart';

class GetTrainingsUseCase {
  const GetTrainingsUseCase(this._repository);
  final TrainingRepository _repository;

  Future<Result<List<Training>>> call() => _repository.getTrainings();
}

class EnrollInTrainingUseCase {
  const EnrollInTrainingUseCase(this._repository);
  final TrainingRepository _repository;

  Future<Result<Training>> call(int trainingId) =>
      _repository.enroll(trainingId);
}
