import 'package:dio/dio.dart';

import '../models/training_dto.dart';

/// Llamadas HTTP de capacitaciones. Lanza [DioException]; el repositorio las mapea.
class TrainingRemoteDataSource {
  const TrainingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<TrainingDto>> published() async {
    final response = await _dio.get<List<dynamic>>('/training/published');
    return response.data!
        .map((e) => TrainingDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> enroll(int trainingId) async {
    await _dio.post<Map<String, dynamic>>('/training/$trainingId/enroll');
  }
}
