import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/coach_conversation.dart';
import '../../domain/entities/coach_reply.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/assistant_remote_data_source.dart';
import '../models/assistant_dto.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  const AssistantRepositoryImpl(this._remote);

  final AssistantRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e) {
      return Result.err(mapDioException(e));
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    }
  }

  @override
  Future<Result<CoachConversation?>> getLatestConversation() =>
      _guard(() async {
        final list = await _remote.conversations();
        if (list.isEmpty) return null;
        // El servidor las ordena de la más reciente a la más antigua.
        final latest = list.first;
        return conversationFrom(
          latest.conversacionId,
          await _remote.messages(latest.conversacionId),
        );
      });

  @override
  Future<Result<List<ConversationSummary>>> getConversations() => _guard(
    () async => [for (final c in await _remote.conversations()) c.toEntity()],
  );

  @override
  Future<Result<CoachConversation>> getConversation(int id) =>
      _guard(() async => conversationFrom(id, await _remote.messages(id)));

  @override
  Future<Result<CoachReply>> ask(
    String message, {
    int? conversationId,
    int? ventureId,
  }) => _guard(
    () async => (await _remote.chat(
      message,
      conversationId: conversationId,
      ventureId: ventureId,
    )).toEntity(),
  );
}
