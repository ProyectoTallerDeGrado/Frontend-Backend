import 'package:dio/dio.dart';

import '../models/training_dto.dart';

/// Llamadas HTTP de capacitaciones. Lanza [DioException]; el repositorio las mapea.
class TrainingRemoteDataSource {
  const TrainingRemoteDataSource(this._dio);

  final Dio _dio;

  /// Capacitaciones programadas (la lista general, paginada; se toma la primera página).
  Future<List<TrainingDto>> all() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/training',
      queryParameters: {'page_size': 100},
    );
    return (response.data!['items'] as List<dynamic>)
        .map((e) => TrainingDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Las capacitaciones en las que el emprendedor está inscrito, con su asistencia.
  Future<List<TrainingDto>> mine() async {
    final response = await _dio.get<List<dynamic>>('/training/me');
    return response.data!
        .map((e) => TrainingDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TrainingDto> enroll(int trainingId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/training/$trainingId/enroll',
    );
    return TrainingDto.fromJson(response.data!);
  }
}
