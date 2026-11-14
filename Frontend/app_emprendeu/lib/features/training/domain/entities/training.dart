/// Una capacitación del programa (CU29).
class Training {
  const Training({
    required this.id,
    required this.title,
    required this.status,
    required this.enrolled,
    this.description,
    this.date,
    this.modality,
    this.kind,
    this.attended,
  });

  final int id;
  final String title;

  /// `programada`, `realizada` o `cancelada`.
  final String status;
  final String? description;
  final DateTime? date;
  final String? modality;
  final String? kind;

  /// El emprendedor ya está inscrito.
  final bool enrolled;

  /// Su asistencia: `null` = todavía sin registrar (solo si está inscrito).
  final bool? attended;

  bool get cancelled => status == 'cancelada';
  bool get canEnroll => !enrolled && status == 'programada';
}
