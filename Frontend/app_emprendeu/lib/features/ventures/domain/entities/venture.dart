/// Emprendimiento del usuario (objeto de negocio puro).
class Venture {
  const Venture({
    required this.id,
    required this.name,
    this.stageName,
    this.description,
    this.sector,
    this.status,
    this.members = const [],
  });

  final int id;
  final String name;

  /// Etapa actual (p. ej. «Incubación»); `null` si aún no tiene.
  final String? stageName;
  final String? description;
  final String? sector;

  /// Estado que fija la coordinación (activo, pausado...); el emprendedor no lo cambia.
  final String? status;

  /// Equipo del emprendimiento (lo arma la coordinación), en orden de ingreso.
  final List<VentureMember> members;
}

/// Integrante del equipo de un emprendimiento.
class VentureMember {
  const VentureMember({
    required this.entrepreneurId,
    required this.name,
    this.role,
  });

  final int entrepreneurId;
  final String name;

  /// `fundador`, `cofundador` o `miembro`.
  final String? role;

  /// Rol para mostrar («Fundador», «Cofundador», «Miembro»).
  String get roleLabel => switch (role) {
    'fundador' => 'Fundador',
    'cofundador' => 'Cofundador',
    'miembro' => 'Miembro',
    null || '' => 'Integrante',
    final other => other[0].toUpperCase() + other.substring(1),
  };
}
