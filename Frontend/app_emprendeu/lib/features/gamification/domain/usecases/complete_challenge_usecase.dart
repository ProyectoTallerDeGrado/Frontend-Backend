import '../../../../core/error/result.dart';
import '../entities/completion_result.dart';
import '../repositories/gamification_repository.dart';

class CompleteChallengeUseCase {
  const CompleteChallengeUseCase(this._repository);

  final GamificationRepository _repository;

  /// [evidenceText] y [documentId] son la evidencia del reto (CU07).
  Future<Result<CompletionResult>> call(
    int challengeId, {
    int? ventureId,
    String? evidenceText,
    int? documentId,
  }) {
    final text = evidenceText?.trim();
    return _repository.completeChallenge(
      challengeId,
      ventureId: ventureId,
      evidenceText: (text == null || text.isEmpty) ? null : text,
      documentId: documentId,
    );
  }
}
