/// Turno de una hora que ofrece un asesor en un día.
class TimeSlot {
  const TimeSlot({
    required this.start,
    required this.label,
    required this.available,
  });

  /// Instante de inicio (el que se envía al agendar).
  final DateTime start;

  /// Hora para mostrar, ya en la zona de la agenda («09:00»).
  final String label;
  final bool available;
}
