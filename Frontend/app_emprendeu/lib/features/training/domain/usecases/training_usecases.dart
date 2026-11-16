import '../../../../core/error/result.dart';
import '../entities/training.dart';
import '../repositories/training_repository.dart';

class GetTrainingsUseCase {
  const GetTrainingsUseCase(this._repository);
  final TrainingRepository _repository;

  Future<Result<TrainingPage>> call({int page = 1}) =>
      _repository.getTrainings(page: page);
}

class EnrollInTrainingUseCase {
  const EnrollInTrainingUseCase(this._repository);
  final TrainingRepository _repository;

  Future<Result<Training>> call(int trainingId) =>
      _repository.enroll(trainingId);
}
