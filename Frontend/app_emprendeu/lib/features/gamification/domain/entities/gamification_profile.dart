/// XP y nivel del emprendedor.
class GamificationProfile {
  const GamificationProfile({
    required this.xp,
    required this.level,
    required this.nextLevelXp,
    required this.missingXp,
    required this.progressPct,
  });

  final int xp;
  final int level;

  /// XP necesario para el siguiente nivel; `null` en el nivel máximo.
  final int? nextLevelXp;
  final int? missingXp;

  /// Avance dentro del nivel actual (0–100).
  final double progressPct;
}
