import '../../../../core/error/result.dart';
import '../entities/journey.dart';
import '../repositories/gamification_repository.dart';

class GetJourneyUseCase {
  const GetJourneyUseCase(this._repository);

  final GamificationRepository _repository;

  Future<Result<Journey>> call() => _repository.getJourney();
}
