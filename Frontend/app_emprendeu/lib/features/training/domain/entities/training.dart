/// Capacitación publicada, con la inscripción y la asistencia de quien consulta.
class Training {
  const Training({
    required this.id,
    required this.title,
    this.description,
    this.date,
    this.modality,
    this.type,
    required this.state,
    required this.enrolledCount,
    required this.enrolled,
    this.attended,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime? date;
  final String? modality;
  final String? type;

  /// `publicada` o `realizada` (los borradores y canceladas no llegan a la app).
  final String state;
  final int enrolledCount;
  final bool enrolled;

  /// `null` = asistencia todavía sin registrar.
  final bool? attended;

  bool get isDone => state == 'realizada';
}
