import 'package:dio/dio.dart';

import '../models/training_dto.dart';

/// Llamadas HTTP de capacitaciones. Lanza [DioException]; el repositorio las mapea.
class TrainingRemoteDataSource {
  const TrainingRemoteDataSource(this._dio);

  final Dio _dio;

  /// Una página de la lista general: las capacitaciones y el total del programa.
  Future<({List<TrainingDto> items, int total})> all({
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/training',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final data = response.data!;
    return (
      items: (data['items'] as List<dynamic>)
          .map((e) => TrainingDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int,
    );
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
