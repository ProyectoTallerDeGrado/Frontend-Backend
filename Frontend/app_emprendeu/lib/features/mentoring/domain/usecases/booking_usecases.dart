import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/booking_status.dart';
import '../entities/history_event.dart';
import '../entities/mentor.dart';
import '../entities/mentoring_session.dart';
import '../entities/time_slot.dart';
import '../repositories/booking_repository.dart';

class GetBookingStatusUseCase {
  const GetBookingStatusUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<BookingStatus>> call() => _repository.getBookingStatus();
}

class GetMentorsUseCase {
  const GetMentorsUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<List<Mentor>>> call() => _repository.getMentors();
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
    );
  }
}

/// Historial del emprendimiento (CU19).
class GetHistoryUseCase {
  const GetHistoryUseCase(this._repository);
  final BookingRepository _repository;

  Future<Result<List<HistoryEvent>>> call({bool newestFirst = true}) =>
      _repository.getHistory(newestFirst: newestFirst);
}
