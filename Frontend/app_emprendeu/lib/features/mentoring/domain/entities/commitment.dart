/// Compromiso asignado por un mentor.
class Commitment {
  const Commitment({
    required this.id,
    required this.sessionId,
    required this.description,
    required this.done,
    this.dueDate,
    this.pendingSync = false,
  });

  final int id;
  final int sessionId;
  final String description;
  final bool done;
  final DateTime? dueDate;

  /// El último cambio se guardó solo en este dispositivo y falta enviarlo.
  final bool pendingSync;

  Commitment copyWith({bool? done, bool? pendingSync}) => Commitment(
    id: id,
    sessionId: sessionId,
    description: description,
    done: done ?? this.done,
    dueDate: dueDate,
    pendingSync: pendingSync ?? this.pendingSync,
  );
}
