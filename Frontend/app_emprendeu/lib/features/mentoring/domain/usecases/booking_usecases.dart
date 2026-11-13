import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/booking_status.dart';
import '../entities/history_event.dart';
import '../entities/history_filter.dart';
import '../entities/mentor.dart';
import '../entities/mentoring_session.dart';
import '../entities/task.dart';
import '../entities/time_slot.dart';
import '../repositories/booking_repository.dart';

class GetBookingStatusUseCase {
  const GetBookingStatusUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<BookingStatus>> call({int? ventureId}) =>
      _repository.getBookingStatus(ventureId: ventureId);
}

class GetMentorsUseCase {
  const GetMentorsUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<List<Mentor>>> call({int? ventureId}) =>
      _repository.getMentors(ventureId: ventureId);
}

class GetSlotsUseCase {
  const GetSlotsUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<List<TimeSlot>>> call(int mentorId, DateTime day) =>
      _repository.getSlots(mentorId, day);
}

class GetMySessionsUseCase {
  const GetMySessionsUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<List<MentoringSession>>> call(
    SessionFilter filter, {
    DateTime? from,
    DateTime? to,
  }) => _repository.getMySessions(filter, from: from, to: to);
}

/// Agenda una mentoría. Antes de confirmar vuelve a pedir los turnos del día:
/// el horario pudo ocuparse mientras la persona decidía (CU10).
class BookSessionUseCase {
  const BookSessionUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<MentoringSession>> call({
    required int mentorId,
    required DateTime day,
    required TimeSlot slot,
    String? topic,
    int? ventureId,
  }) async {
    final fresh = await _repository.getSlots(mentorId, day);
    switch (fresh) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final value):
        final stillFree = value.any(
          (s) => s.available && s.start.isAtSameMomentAs(slot.start),
        );
        if (!stillFree) return const Result.err(SlotUnavailableFailure());
    }
    final cleaned = topic?.trim();
    return _repository.book(
      mentorId: mentorId,
      start: slot.start,
      topic: (cleaned == null || cleaned.isEmpty) ? null : cleaned,
      ventureId: ventureId,
    );
  }
}

/// Historial del emprendimiento (CU19).
class GetHistoryUseCase {
  const GetHistoryUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<List<HistoryEvent>>> call({
    HistoryFilter filter = const HistoryFilter(),
    int? ventureId,
  }) => _repository.getHistory(filter: filter, ventureId: ventureId);
}

/// Detalle de una mentoría propia (CU23).
class GetSessionUseCase {
  const GetSessionUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<MentoringSession>> call(int id) => _repository.getSession(id);
}

/// Cancela una mentoría programada y libera el horario (CU23).
class CancelSessionUseCase {
  const CancelSessionUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<MentoringSession>> call(int id) =>
      _repository.cancelSession(id);
}

/// Compromisos e hitos del emprendedor con sus filtros (CU22).
class GetTasksUseCase {
  const GetTasksUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<List<Task>>> call(TaskFilter filter) =>
      _repository.getTasks(filter);
}
