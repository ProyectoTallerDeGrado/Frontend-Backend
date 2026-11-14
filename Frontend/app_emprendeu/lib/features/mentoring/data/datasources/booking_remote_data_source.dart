import 'package:dio/dio.dart';

import '../../domain/entities/history_event.dart';
import '../../domain/entities/history_filter.dart';
import '../../domain/entities/mentoring_session.dart';
import '../../domain/entities/task.dart';
import '../models/booking_dto.dart';
import '../models/history_dto.dart';
import '../models/task_dto.dart';

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

  static String _kindCode(HistoryKind kind) => switch (kind) {
    HistoryKind.session => 'sesion',
    HistoryKind.progress => 'avance',
    HistoryKind.milestone => 'hito',
    HistoryKind.recommendation => 'recomendacion',
    HistoryKind.commitment => 'compromiso',
    HistoryKind.stage => 'etapa',
  };

  Future<List<HistoryEventDto>> history({
    required HistoryFilter filter,
    int? ventureId,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ventureId == null
          ? '/mentoring/ventures/me/history'
          : '/mentoring/ventures/$ventureId/history',
      queryParameters: {
        'orden': filter.newestFirst ? 'desc' : 'asc',
        // FastAPI lee `tipo=a&tipo=b`; el formato por defecto de Dio manda `tipo[]=a`.
        if (filter.kinds.isNotEmpty)
          'tipo': [for (final k in filter.kinds) _kindCode(k)],
        if (filter.from != null) 'desde': _day(filter.from!),
        if (filter.to != null) 'hasta': _day(filter.to!),
      },
      options: Options(listFormat: ListFormat.multi),
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

  Future<MentoringSessionDto> session(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/mentoring/sessions/$id',
    );
    return MentoringSessionDto.fromJson(response.data!);
  }

  Future<MentoringSessionDto> cancel(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/mentoring/sessions/$id/cancel',
    );
    return MentoringSessionDto.fromJson(response.data!);
  }

  Future<List<TaskDto>> tasks(TaskFilter filter) async {
    final response = await _dio.get<List<dynamic>>(
      '/mentoring/tasks/me',
      queryParameters: {
        if (filter.kind != null)
          'tipo': filter.kind == TaskKind.milestone ? 'hito' : 'compromiso',
        'estado': filter.state == TaskState.done ? 'cumplido' : 'pendiente',
        if (filter.from != null) 'desde': _day(filter.from!),
        if (filter.to != null) 'hasta': _day(filter.to!),
      },
    );
    return response.data!
        .map((e) => TaskDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
