/// Emprendimiento del usuario (objeto de negocio puro).
class Venture {
  const Venture({
    required this.id,
    required this.name,
    this.stageName,
    this.description,
    this.sector,
    this.status,
  });

  final int id;
  final String name;

  /// Etapa actual (p. ej. «Incubación»); `null` si aún no tiene.
  final String? stageName;
  final String? description;
  final String? sector;

  /// Estado que fija la coordinación (activo, pausado...); el emprendedor no lo cambia.
  final String? status;
}
