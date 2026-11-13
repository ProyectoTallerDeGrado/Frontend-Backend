import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/booking_status.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/history_event.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/history_filter.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/mentor.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/mentoring_session.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/task.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/time_slot.dart';
import 'package:app_emprendeu/features/mentoring/domain/repositories/booking_repository.dart';

final DateTime tomorrow9 = DateTime.utc(2030, 1, 15, 13);

const marcelo = Mentor(id: 11, name: 'Marcelo Cuellar', specialty: 'Marketing');

/// Repositorio en memoria de la agenda. Puede simular que otra persona ocupa el
/// horario entre que se muestra y se confirma ([takeOnRead]).
class FakeBookingRepository implements BookingRepository {
  FakeBookingRepository({
    this.status = const BookingStatus(enabled: true),
    List<Mentor>? mentors,
    List<MentoringSession>? sessions,
    this.takeOnRead,
  }) : mentors = mentors ?? [marcelo],
       sessions =
           sessions ??
           [
             MentoringSession(
               id: 1,
               state: SessionState.scheduled,
               topic: 'Costos',
               mentorName: 'Marcelo Cuellar',
               specialty: 'Marketing',
               scheduledAt: DateTime.now().add(const Duration(days: 3)),
             ),
             MentoringSession(
               id: 2,
               state: SessionState.done,
               topic: 'Propuesta de valor',
               mentorName: 'Marcelo Cuellar',
               doneAt: DateTime.now().subtract(const Duration(days: 9)),
               recommendations: 2,
               commitments: 1,
             ),
           ];

  BookingStatus status;
  List<Mentor> mentors;
  final List<MentoringSession> sessions;

  /// Cuántas lecturas de turnos pasan antes de que alguien ocupe el horario.
  int? takeOnRead;
  final Set<DateTime> _taken = {};
  int slotReads = 0;
  int bookCalls = 0;
  String? lastTopic;

  /// Último emprendimiento con el que se agendó.
  int? lastVentureId;

  @override
  Future<Result<BookingStatus>> getBookingStatus({int? ventureId}) async =>
      Result.ok(status);

  @override
  Future<Result<List<Mentor>>> getMentors({int? ventureId}) async =>
      Result.ok(mentors);

  @override
  Future<Result<List<TimeSlot>>> getSlots(int mentorId, DateTime day) async {
    slotReads++;
    if (takeOnRead != null && slotReads >= takeOnRead!) _taken.add(tomorrow9);
    return Result.ok([
      TimeSlot(
        start: tomorrow9,
        label: '09:00',
        available: !_taken.contains(tomorrow9),
      ),
      TimeSlot(
        start: tomorrow9.add(const Duration(hours: 1)),
        label: '10:00',
        available: true,
      ),
    ]);
  }

  @override
  Future<Result<MentoringSession>> book({
    required int mentorId,
    required DateTime start,
    String? topic,
    int? ventureId,
  }) async {
    bookCalls++;
    lastTopic = topic;
    lastVentureId = ventureId;
    if (_taken.contains(start)) {
      return const Result.err(SlotUnavailableFailure());
    }
    final created = MentoringSession(
      id: 100 + bookCalls,
      state: SessionState.scheduled,
      topic: topic,
      mentorName: 'Marcelo Cuellar',
      scheduledAt: start,
    );
    sessions.add(created);
    return Result.ok(created);
  }

  List<HistoryEvent> history = [
    HistoryEvent(
      kind: HistoryKind.session,
      refId: 1,
      date: DateTime.utc(2030, 1, 10, 14),
      title: 'Costos',
      state: 'realizada',
      author: 'Marcelo Cuellar',
    ),
    const HistoryEvent(
      kind: HistoryKind.milestone,
      refId: 2,
      title: 'Primer prototipo',
      state: 'pendiente',
    ),
  ];
  HistoryFilter? lastFilter;
  bool? get lastNewestFirst => lastFilter?.newestFirst;

  @override
  Future<Result<List<HistoryEvent>>> getHistory({
    HistoryFilter filter = const HistoryFilter(),
    int? ventureId,
  }) async {
    lastFilter = filter;
    return Result.ok([
      for (final e in history)
        if (filter.kinds.isEmpty || filter.kinds.contains(e.kind)) e,
    ]);
  }

  /// Si se indica, [cancelSession] falla con él (p. ej. `SessionClosedFailure`).
  Failure? cancelFailure;
  int cancelCalls = 0;

  @override
  Future<Result<MentoringSession>> getSession(int id) async {
    for (final s in sessions) {
      if (s.id == id) return Result.ok(s);
    }
    return const Result.err(UnknownFailure('Mentoría no encontrada.'));
  }

  @override
  Future<Result<MentoringSession>> cancelSession(int id) async {
    cancelCalls++;
    if (cancelFailure != null) return Result.err(cancelFailure!);
    final index = sessions.indexWhere((s) => s.id == id);
    if (index < 0) {
      return const Result.err(UnknownFailure('Mentoría no encontrada.'));
    }
    final old = sessions[index];
    final cancelled = MentoringSession(
      id: old.id,
      state: SessionState.cancelled,
      topic: old.topic,
      mentorName: old.mentorName,
      specialty: old.specialty,
      scheduledAt: old.scheduledAt,
    );
    sessions[index] = cancelled;
    return Result.ok(cancelled);
  }

  List<Task> tasks = [
    Task(
      kind: TaskKind.commitment,
      refId: 1,
      ventureId: 1,
      title: 'Entrevistar 5 clientes',
      responsible: 'Camila Justiniano',
      state: TaskState.pending,
      dueAt: DateTime.now().add(const Duration(days: 5)),
    ),
    Task(
      kind: TaskKind.commitment,
      refId: 2,
      ventureId: 1,
      title: 'Enviar cotización',
      state: TaskState.pending,
      dueAt: DateTime.now().subtract(const Duration(days: 2)),
      overdue: true,
    ),
    const Task(
      kind: TaskKind.milestone,
      refId: 7,
      ventureId: 1,
      title: 'Primer prototipo',
      state: TaskState.pending,
    ),
    const Task(
      kind: TaskKind.milestone,
      refId: 8,
      ventureId: 1,
      title: 'Registro de marca',
      state: TaskState.done,
    ),
  ];
  TaskFilter? lastTaskFilter;

  @override
  Future<Result<List<Task>>> getTasks(TaskFilter filter) async {
    lastTaskFilter = filter;
    return Result.ok([
      for (final t in tasks)
        if (t.state == filter.state &&
            (filter.kind == null || t.kind == filter.kind))
          t,
    ]);
  }

  @override
  Future<Result<List<MentoringSession>>> getMySessions(
    SessionFilter filter, {
    DateTime? from,
    DateTime? to,
  }) async {
    final wanted = switch (filter) {
      SessionFilter.upcoming => SessionState.scheduled,
      SessionFilter.done => SessionState.done,
      SessionFilter.cancelled => SessionState.cancelled,
    };
    return Result.ok([
      for (final s in sessions)
        if (s.state == wanted) s,
    ]);
  }
}
