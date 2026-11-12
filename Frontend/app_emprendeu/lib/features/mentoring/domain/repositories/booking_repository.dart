import '../../../../core/error/result.dart';
import '../entities/booking_status.dart';
import '../entities/history_event.dart';
import '../entities/mentor.dart';
import '../entities/mentoring_session.dart';
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

  /// Línea de tiempo del emprendimiento del usuario; [newestFirst] invierte el orden.
  Future<Result<List<HistoryEvent>>> getHistory({
    bool newestFirst = true,
    int? ventureId,
  });

  /// Sesiones del usuario; [from] y [to] son días inclusive.
  Future<Result<List<MentoringSession>>> getMySessions(
    SessionFilter filter, {
    DateTime? from,
    DateTime? to,
  });
}
