/// Emprendimiento del usuario (objeto de negocio puro).
class Venture {
  const Venture({required this.id, required this.name, this.stageName});

  final int id;
  final String name;

  /// Etapa actual (p. ej. «Incubación»); `null` si aún no tiene.
  final String? stageName;
}
