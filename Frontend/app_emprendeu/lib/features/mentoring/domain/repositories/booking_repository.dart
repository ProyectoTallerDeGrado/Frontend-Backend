import '../../../../core/error/result.dart';
import '../entities/booking_status.dart';
import '../entities/history_event.dart';
import '../entities/history_filter.dart';
import '../entities/mentor.dart';
import '../entities/mentoring_session.dart';
import '../entities/task.dart';
import '../entities/time_slot.dart';

/// Agendar mentorías y consultar las sesiones propias (requiere conexión).
abstract interface class BookingRepository {
  /// [ventureId] = emprendimiento activo; sin indicarlo, el primero del usuario.
  Future<Result<BookingStatus>> getBookingStatus({int? ventureId});

  /// Asesores asignados al emprendimiento (y habilitados).
  Future<Result<List<Mentor>>> getMentors({int? ventureId});

  /// Turnos del asesor en [day] (día de la agenda).
  Future<Result<List<TimeSlot>>> getSlots(int mentorId, DateTime day);

  Future<Result<MentoringSession>> book({
    required int mentorId,
    required DateTime start,
    String? topic,
    int? ventureId,
  });

  /// Línea de tiempo del emprendimiento del usuario, con orden, tipos y periodo de [filter].
  Future<Result<List<HistoryEvent>>> getHistory({
    HistoryFilter filter = const HistoryFilter(),
    int? ventureId,
  });

  /// Detalle de una sesión en la que participa el usuario.
  Future<Result<MentoringSession>> getSession(int id);

  /// Cancela una sesión programada (la libera para otros). `session_closed` si ya no se puede.
  Future<Result<MentoringSession>> cancelSession(int id);

  /// Compromisos e hitos del usuario según [filter] (CU22).
  Future<Result<List<Task>>> getTasks(TaskFilter filter);

  /// Sesiones del usuario; [from] y [to] son días inclusive.
  Future<Result<List<MentoringSession>>> getMySessions(
    SessionFilter filter, {
    DateTime? from,
    DateTime? to,
  });
}
