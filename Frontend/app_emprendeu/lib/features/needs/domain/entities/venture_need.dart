/// Si lo que se reporta es algo que falta (necesidad) o algo que frena (dificultad).
enum NeedKind { need, difficulty }

enum NeedPriority { low, medium, high }

/// Un rubro del catálogo del CIE-U (financiamiento, marketing, legal…).
class NeedCategory {
  const NeedCategory({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;
}

/// Una necesidad o dificultad que el emprendedor reportó (CU24).
class VentureNeed {
  const VentureNeed({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.kind,
    required this.priority,
    required this.resolved,
    this.description,
    this.detectedAt,
    this.resolvedAt,
  });

  final int id;
  final int categoryId;
  final String categoryName;
  final NeedKind kind;
  final NeedPriority priority;

  /// El CIE-U ya la atendió.
  final bool resolved;
  final String? description;
  final DateTime? detectedAt;
  final DateTime? resolvedAt;
}
