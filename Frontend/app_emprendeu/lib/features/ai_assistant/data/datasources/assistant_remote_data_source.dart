import 'package:dio/dio.dart';

import '../models/assistant_dto.dart';

/// Llamadas HTTP del coach. Lanza [DioException]; el repositorio las mapea.
class AssistantRemoteDataSource {
  const AssistantRemoteDataSource(this._dio);

  final Dio _dio;

  /// El modelo local puede tardar bastante más que una consulta normal.
  static const _chatTimeout = Duration(seconds: 90);

  Future<List<ConversationSummaryDto>> conversations() async {
    final response = await _dio.get<List<dynamic>>('/ai/conversations/me');
    return response.data!
        .map((e) => ConversationSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessageDto>> messages(int conversationId) async {
    final response = await _dio.get<List<dynamic>>(
      '/ai/conversations/$conversationId/messages',
    );
    return response.data!
        .map((e) => ChatMessageDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatReplyDto> chat(
    String message, {
    int? conversationId,
    int? ventureId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ai/chat',
      data: {
        'mensaje': message,
        'conversacion_id': ?conversationId,
        'emprendimiento_id': ?ventureId,
      },
      options: Options(receiveTimeout: _chatTimeout, sendTimeout: _chatTimeout),
    );
    return ChatReplyDto.fromJson(response.data!);
  }
}
