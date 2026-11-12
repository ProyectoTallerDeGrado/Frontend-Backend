import 'package:dio/dio.dart';

import '../../domain/entities/mentoring_session.dart';
import '../models/booking_dto.dart';
import '../models/history_dto.dart';

/// Llamadas HTTP de agenda. Lanza [DioException]; el repositorio las mapea.
class BookingRemoteDataSource {
  const BookingRemoteDataSource(this._dio);

  final Dio _dio;

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<BookingStatusDto> bookingStatus({int? ventureId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/mentoring/booking-status',
      queryParameters: {'emprendimiento_id': ?ventureId},
    );
    return BookingStatusDto.fromJson(response.data!);
  }

  Future<List<MentorDto>> mentors({int? ventureId}) async {
    final response = await _dio.get<List<dynamic>>(
      '/mentoring/mentors',
      queryParameters: {'emprendimiento_id': ?ventureId},
    );
    return response.data!
        .map((e) => MentorDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SlotDto>> slots(int mentorId, DateTime day) async {
    final response = await _dio.get<List<dynamic>>(
      '/mentoring/mentors/$mentorId/slots',
      queryParameters: {'fecha': _day(day)},
    );
    return response.data!
        .map((e) => SlotDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MentoringSessionDto> book({
    required int mentorId,
    required DateTime start,
    String? topic,
    int? ventureId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/mentoring/sessions',
      data: {
        'mentor_id': mentorId,
        'inicio': start.toUtc().toIso8601String(),
        'tema': ?topic,
        'emprendimiento_id': ?ventureId,
      },
    );
    return MentoringSessionDto.fromJson(response.data!);
  }

  Future<List<HistoryEventDto>> history({
    required bool newestFirst,
    int? ventureId,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ventureId == null
          ? '/mentoring/ventures/me/history'
          : '/mentoring/ventures/$ventureId/history',
      queryParameters: {'orden': newestFirst ? 'desc' : 'asc'},
    );
    return response.data!
        .map((e) => HistoryEventDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MentoringSessionDto>> mySessions(
    SessionFilter filter, {
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/mentoring/sessions/me',
      queryParameters: {
        'filtro': switch (filter) {
          SessionFilter.upcoming => 'proximas',
          SessionFilter.done => 'realizadas',
          SessionFilter.cancelled => 'canceladas',
        },
        if (from != null) 'desde': _day(from),
        if (to != null) 'hasta': _day(to),
      },
    );
    return response.data!
        .map((e) => MentoringSessionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
