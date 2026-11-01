/// Resultado de cumplir un reto.
class CompletionResult {
  const CompletionResult({
    required this.challengeId,
    required this.xpAwarded,
    required this.xpTotal,
    required this.level,
    required this.leveledUp,
    required this.newBadges,
  });

  final int challengeId;

  /// XP ganado ahora (reto + insignias nuevas).
  final int xpAwarded;
  final int xpTotal;
  final int level;
  final bool leveledUp;
  final List<String> newBadges;
}
