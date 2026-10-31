import '../../../../core/error/result.dart';
import '../entities/gamification_profile.dart';
import '../repositories/gamification_repository.dart';

class GetGamificationProfileUseCase {
  const GetGamificationProfileUseCase(this._repository);

  final GamificationRepository _repository;

  Future<Result<GamificationProfile>> call() => _repository.getProfile();
}
