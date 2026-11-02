enum SessionState { scheduled, done, cancelled }

/// Filtro de la lista «Mentorías».
enum SessionFilter { upcoming, done, cancelled }

/// Sesión de acompañamiento (agendada, realizada o cancelada).
class MentoringSession {
  const MentoringSession({
    required this.id,
    required this.state,
    this.topic,
    this.modality,
    this.mentorName,
    this.specialty,
    this.ventureName,
    this.scheduledAt,
    this.doneAt,
    this.notes,
    this.recommendations = 0,
    this.commitments = 0,
  });

  final int id;
  final SessionState state;
  final String? topic;
  final String? modality;
  final String? mentorName;
  final String? specialty;
  final String? ventureName;
  final DateTime? scheduledAt;
  final DateTime? doneAt;
  final String? notes;
  final int recommendations;
  final int commitments;

  /// Cuándo ocurre u ocurrió: lo realizado manda sobre lo programado.
  DateTime? get when => doneAt ?? scheduledAt;
}
