enum ChallengeStatus { done, current, locked }

enum StageStatus { done, current, locked }

class JourneyStage {
  const JourneyStage({
    required this.id,
    required this.name,
    required this.status,
  });

  final int id;
  final String name;
  final StageStatus status;
}

class JourneyChallenge {
  const JourneyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.stageName,
    required this.xp,
    required this.status,
    this.completedAt,
  });

  final int id;
  final String title;
  final String? description;
  final String? stageName;
  final int xp;
  final ChallengeStatus status;
  final DateTime? completedAt;
}

/// Camino de retos de un emprendimiento (objeto de negocio puro).
class Journey {
  const Journey({
    required this.ventureId,
    required this.xp,
    required this.level,
    required this.stages,
    required this.challenges,
  });

  final int ventureId;
  final int xp;
  final int level;
  final List<JourneyStage> stages;
  final List<JourneyChallenge> challenges;

  /// Primer reto pendiente (el único desbloqueado), o `null` si todo está cumplido.
  JourneyChallenge? get nextChallenge {
    for (final c in challenges) {
      if (c.status == ChallengeStatus.current) return c;
    }
    return null;
  }

  int get doneCount =>
      challenges.where((c) => c.status == ChallengeStatus.done).length;
}
