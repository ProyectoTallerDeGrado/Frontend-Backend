import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/booking_status.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/history_event.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/mentor.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/mentoring_session.dart';
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
  bool? lastNewestFirst;

  @override
  Future<Result<List<HistoryEvent>>> getHistory({
    bool newestFirst = true,
    int? ventureId,
  }) async {
    lastNewestFirst = newestFirst;
    return Result.ok(history);
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
