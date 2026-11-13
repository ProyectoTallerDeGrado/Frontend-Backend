import 'package:dio/dio.dart';

import '../../domain/entities/venture_need.dart';
import '../models/needs_dto.dart';

/// Llamadas HTTP de necesidades. Lanza [DioException]; el repositorio las mapea.
class NeedsRemoteDataSource {
  const NeedsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<NeedCategoryDto>> categories() async {
    final response = await _dio.get<List<dynamic>>('/needs');
    return response.data!
        .map((e) => NeedCategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VentureNeedDto>> needs(int ventureId) async {
    final response = await _dio.get<List<dynamic>>(
      '/ventures/$ventureId/needs',
    );
    return response.data!
        .map((e) => VentureNeedDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VentureNeedDto> report({
    required int ventureId,
    required int categoryId,
    required NeedKind kind,
    required NeedPriority priority,
    required String description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ventures/$ventureId/needs',
      data: {
        'necesidad_id': categoryId,
        'tipo': kind == NeedKind.difficulty ? 'dificultad' : 'necesidad',
        'prioridad': switch (priority) {
          NeedPriority.high => 'alta',
          NeedPriority.low => 'baja',
          NeedPriority.medium => 'media',
        },
        'descripcion': description,
      },
    );
    return VentureNeedDto.fromJson(response.data!);
  }
}
