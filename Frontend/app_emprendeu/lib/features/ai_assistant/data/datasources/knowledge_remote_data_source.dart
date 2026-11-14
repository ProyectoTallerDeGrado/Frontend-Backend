import 'package:dio/dio.dart';

import '../models/knowledge_dto.dart';

/// Índice descargable de la base de conocimiento del CIE-U.
class KnowledgeRemoteDataSource {
  const KnowledgeRemoteDataSource(this._dio);

  final Dio _dio;
  static const _pageSize = 100; // máximo que acepta el contrato

  Future<KnowledgeIndexDto> index() async {
    final res = await _dio.get<Map<String, dynamic>>('/ai/knowledge/index');
    return KnowledgeIndexDto.fromJson(res.data!);
  }

  /// Todos los fragmentos de un documento, solo el texto (sin vectores del servidor).
  Future<List<FragmentDto>> fragments(int documentId) async {
    final out = <FragmentDto>[];
    for (var page = 1; ; page++) {
      final res = await _dio.get<Map<String, dynamic>>(
        '/ai/knowledge/$documentId/fragments',
        queryParameters: {
          'page': page,
          'page_size': _pageSize,
          'incluir_embedding': false,
        },
      );
      final data = res.data!;
      final items = (data['items'] as List)
          .map((e) => FragmentDto.fromJson(e as Map<String, dynamic>))
          .toList();
      out.addAll(items);
      if (items.isEmpty || out.length >= (data['total'] as int)) return out;
    }
  }
}
