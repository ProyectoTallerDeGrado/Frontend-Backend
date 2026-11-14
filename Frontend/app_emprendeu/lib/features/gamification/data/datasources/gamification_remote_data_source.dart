import 'package:dio/dio.dart';

import '../models/gamification_dto.dart';
import '../models/journey_dto.dart';

class GamificationRemoteDataSource {
  const GamificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<JourneyDto> journey({int? ventureId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/journey',
      queryParameters: {'emprendimiento_id': ?ventureId},
    );
    return JourneyDto.fromJson(response.data!);
  }

  Future<CompletionDto> complete(
    int challengeId, {
    int? ventureId,
    String? evidenceText,
    int? documentId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/journey/challenges/$challengeId/complete',
      data: {'evidencia_texto': ?evidenceText, 'documento_id': ?documentId},
      queryParameters: {'emprendimiento_id': ?ventureId},
    );
    return CompletionDto.fromJson(response.data!);
  }

  Future<GamificationProfileDto> profile() async {
    final response = await _dio.get<Map<String, dynamic>>('/gamification/me');
    return GamificationProfileDto.fromJson(response.data!);
  }
}
