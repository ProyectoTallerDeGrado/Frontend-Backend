/// Insignia del catálogo con el avance del emprendedor.
class BadgeProgress {
  const BadgeProgress({
    required this.id,
    required this.name,
    this.criterion,
    required this.xpReward,
    required this.earned,
    this.earnedAt,
  });

  final int id;
  final String name;
  final String? criterion;
  final int xpReward;
  final bool earned;
  final DateTime? earnedAt;
}

/// Un movimiento de XP (reto cumplido, insignia...).
class XpMovement {
  const XpMovement({this.reason, required this.amount, this.date});

  final String? reason;
  final int amount;
  final DateTime? date;
}

/// XP, nivel, insignias e historial del emprendedor.
class GamificationProfile {
  const GamificationProfile({
    required this.xp,
    required this.level,
    required this.nextLevelXp,
    required this.missingXp,
    required this.progressPct,
    this.badges = const [],
    this.history = const [],
  });

  final int xp;
  final int level;

  /// XP necesario para el siguiente nivel; `null` en el nivel máximo.
  final int? nextLevelXp;
  final int? missingXp;

  /// Avance dentro del nivel actual (0–100).
  final double progressPct;

  final List<BadgeProgress> badges;
  final List<XpMovement> history;

  /// Insignias ya obtenidas.
  List<BadgeProgress> get earnedBadges => [
    for (final b in badges)
      if (b.earned) b,
  ];
}
