enum TaskKind { commitment, milestone }

enum TaskState { pending, done }

/// Una tarea del emprendedor: un compromiso con su asesor o un hito (CU22).
class Task {
  const Task({
    required this.kind,
    required this.refId,
    required this.ventureId,
    required this.title,
    this.detail,
    this.responsible,
    required this.state,
    this.dueAt,
    this.overdue = false,
  });

  final TaskKind kind;
  final int refId;
  final int ventureId;
  final String title;
  final String? detail;
  final String? responsible;
  final TaskState state;

  /// Fecha prevista (límite del compromiso o estimada del hito).
  final DateTime? dueAt;

  /// Pendiente y con la fecha ya vencida.
  final bool overdue;
}

/// Qué tareas se muestran. Por defecto, las pendientes de cualquier tipo.
class TaskFilter {
  const TaskFilter({
    this.kind,
    this.state = TaskState.pending,
    this.from,
    this.to,
  });

  final TaskKind? kind;
  final TaskState state;
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) =>
      other is TaskFilter &&
      other.kind == kind &&
      other.state == state &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(kind, state, from, to);
}
