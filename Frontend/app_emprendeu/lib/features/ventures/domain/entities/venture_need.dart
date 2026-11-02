/// Necesidad o dificultad que el emprendedor registra en su emprendimiento (CU24).
class VentureNeed {
  const VentureNeed({
    required this.id,
    required this.name,
    required this.resolved,
    required this.priority,
    this.detectedAt,
    this.resolvedAt,
  });

  /// Identificador del registro `emprendimiento_necesidades` (para marcarla resuelta).
  final int id;
  final String name;
  final bool resolved;

  /// `baja`, `media` o `alta`.
  final String priority;
  final DateTime? detectedAt;
  final DateTime? resolvedAt;
}
