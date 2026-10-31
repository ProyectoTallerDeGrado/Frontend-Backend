import '../../../../core/error/result.dart';
import '../entities/completion_result.dart';
import '../entities/gamification_profile.dart';
import '../entities/journey.dart';

abstract interface class GamificationRepository {
  Future<Result<Journey>> getJourney();

  Future<Result<CompletionResult>> completeChallenge(int challengeId);

  Future<Result<GamificationProfile>> getProfile();
}
