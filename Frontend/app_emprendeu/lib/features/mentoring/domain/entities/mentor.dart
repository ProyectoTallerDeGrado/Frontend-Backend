/// Asesor asignado al emprendimiento del usuario.
class Mentor {
  const Mentor({
    required this.id,
    required this.name,
    this.specialty,
    this.locked = false,
    this.lockReason,
  });

  final int id;
  final String name;
  final String? specialty;

  /// Aún no se puede agendar con él (p. ej. falta cumplir un reto).
  final bool locked;
  final String? lockReason;
}
