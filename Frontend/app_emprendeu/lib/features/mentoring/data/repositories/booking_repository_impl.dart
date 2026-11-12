import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/history_event.dart';
import '../../domain/entities/mentor.dart';
import '../../domain/entities/mentoring_session.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  const BookingRepositoryImpl(this._remote);

  final BookingRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e) {
      return Result.err(mapDioException(e));
    } on FormatException {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    }
  }

  @override
  Future<Result<BookingStatus>> getBookingStatus({int? ventureId}) => _guard(
    () async => (await _remote.bookingStatus(ventureId: ventureId)).toEntity(),
  );

  @override
  Future<Result<List<Mentor>>> getMentors({int? ventureId}) => _guard(
    () async => [
      for (final m in await _remote.mentors(ventureId: ventureId)) m.toEntity(),
    ],
  );

  @override
  Future<Result<List<TimeSlot>>> getSlots(int mentorId, DateTime day) => _guard(
    () async => [
      for (final s in await _remote.slots(mentorId, day)) s.toEntity(),
    ],
  );

  @override
  Future<Result<MentoringSession>> book({
    required int mentorId,
    required DateTime start,
    String? topic,
    int? ventureId,
  }) => _guard(
    () async => (await _remote.book(
      mentorId: mentorId,
      start: start,
      topic: topic,
      ventureId: ventureId,
    )).toEntity(),
  );

  @override
  Future<Result<List<HistoryEvent>>> getHistory({
    bool newestFirst = true,
    int? ventureId,
  }) => _guard(
    () async => [
      for (final e in await _remote.history(
        newestFirst: newestFirst,
        ventureId: ventureId,
      ))
        e.toEntity(),
    ],
  );

  @override
  Future<Result<List<MentoringSession>>> getMySessions(
    SessionFilter filter, {
    DateTime? from,
    DateTime? to,
  }) => _guard(
    () async => [
      for (final s in await _remote.mySessions(filter, from: from, to: to))
        s.toEntity(),
    ],
  );
}
