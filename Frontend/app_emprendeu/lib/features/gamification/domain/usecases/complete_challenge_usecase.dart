import '../../../../core/error/result.dart';
import '../entities/completion_result.dart';
import '../repositories/gamification_repository.dart';

class CompleteChallengeUseCase {
  const CompleteChallengeUseCase(this._repository);

  final GamificationRepository _repository;

  Future<Result<CompletionResult>> call(int challengeId) =>
      _repository.completeChallenge(challengeId);
}
