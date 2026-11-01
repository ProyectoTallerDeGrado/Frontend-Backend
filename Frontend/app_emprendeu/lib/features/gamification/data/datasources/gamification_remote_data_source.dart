import 'package:dio/dio.dart';

import '../models/gamification_dto.dart';
import '../models/journey_dto.dart';

class GamificationRemoteDataSource {
  const GamificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<JourneyDto> journey() async {
    final response = await _dio.get<Map<String, dynamic>>('/journey');
    return JourneyDto.fromJson(response.data!);
  }

  Future<CompletionDto> complete(int challengeId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/journey/challenges/$challengeId/complete',
    );
    return CompletionDto.fromJson(response.data!);
  }

  Future<GamificationProfileDto> profile() async {
    final response = await _dio.get<Map<String, dynamic>>('/gamification/me');
    return GamificationProfileDto.fromJson(response.data!);
  }
}
