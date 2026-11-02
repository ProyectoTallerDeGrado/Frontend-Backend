/// Tipo de hecho en la vida del emprendimiento.
enum HistoryKind {
  session,
  progress,
  milestone,
  recommendation,
  commitment,
  stage,
}

/// Un hecho de la línea de tiempo del emprendimiento (CU19).
class HistoryEvent {
  const HistoryEvent({
    required this.kind,
    required this.refId,
    this.date,
    required this.title,
    this.detail,
    this.state,
    this.author,
  });

  final HistoryKind kind;
  final int refId;

  /// Los hitos sin ninguna fecha no la tienen y van al final.
  final DateTime? date;
  final String title;
  final String? detail;
  final String? state;
  final String? author;
}
