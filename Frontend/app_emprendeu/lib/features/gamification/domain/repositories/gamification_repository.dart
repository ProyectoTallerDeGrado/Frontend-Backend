import '../../../../core/error/result.dart';
import '../entities/completion_result.dart';
import '../entities/gamification_profile.dart';
import '../entities/journey.dart';

abstract interface class GamificationRepository {
  /// Camino de [ventureId]; sin indicarlo, el del primer emprendimiento.
  Future<Result<Journey>> getJourney({int? ventureId});

  Future<Result<CompletionResult>> completeChallenge(
    int challengeId, {
    int? ventureId,
    String? evidenceText,
    int? documentId,
  });

  Future<Result<GamificationProfile>> getProfile();
}
