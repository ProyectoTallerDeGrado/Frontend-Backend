import 'package:dio/dio.dart';

import '../../domain/entities/picked_file.dart';
import '../models/evidence_dto.dart';

/// Llamadas HTTP de documentos. Lanza [DioException]; el repositorio las mapea.
class DocumentsRemoteDataSource {
  const DocumentsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<EvidenceDto> upload({
    required int ventureId,
    int? milestoneId,
    required PickedFile file,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
      'emprendimiento_id': ventureId,
      'hito_id': ?milestoneId,
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/documents',
      data: form,
    );
    return EvidenceDto.fromJson(response.data!);
  }

  Future<List<EvidenceDto>> listForVenture(int ventureId) async {
    final response = await _dio.get<List<dynamic>>(
      '/documents',
      queryParameters: {'emprendimiento_id': ventureId},
    );
    return response.data!
        .map((e) => EvidenceDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
