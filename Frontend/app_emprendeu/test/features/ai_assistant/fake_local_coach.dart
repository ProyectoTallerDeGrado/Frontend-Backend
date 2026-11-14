import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/knowledge_match.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/local_knowledge_status.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/repositories/local_coach_repository.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/repositories/local_knowledge_repository.dart';

/// Base de conocimiento local en memoria: [matches] es lo que devuelve la búsqueda.
class FakeLocalKnowledgeRepository implements LocalKnowledgeRepository {
  FakeLocalKnowledgeRepository({
    this.matches = const [],
    this.current = LocalKnowledgeStatus.empty,
  });

  List<KnowledgeMatch> matches;
  LocalKnowledgeStatus current;
  int syncCalls = 0;
  Failure? syncFailure;

  @override
  Future<Result<LocalKnowledgeStatus>> status() async => Ok(current);

  @override
  Future<Result<LocalKnowledgeStatus>> sync({
    void Function(int done, int total)? onProgress,
  }) async {
    syncCalls++;
    if (syncFailure case final f?) return Err(f);
    onProgress?.call(1, 1);
    current = LocalKnowledgeStatus(
      documents: current.documents,
      fragments: current.fragments,
      syncedAt: DateTime.now(),
    );
    return Ok(current);
  }

  @override
  Future<Result<List<KnowledgeMatch>>> search(
    String query, {
    required int limit,
  }) async => Ok(matches.take(limit).toList());
}

/// Modelo del celular que responde [answer] en dos trozos, y guarda en memoria.
class FakeLocalCoachRepository implements LocalCoachRepository {
  FakeLocalCoachRepository({this.answer = 'Respuesta local.', this.failure});

  String answer;
  Failure? failure;
  int generateCalls = 0;
  String lastPrompt = '';
  List<ChatMessage> stored = [];

  @override
  Future<Result<String>> generate({
    required String system,
    required String prompt,
    required void Function(String partial) onPartial,
  }) async {
    generateCalls++;
    lastPrompt = prompt;
    if (failure case final f?) return Err(f);
    onPartial(answer.substring(0, answer.length ~/ 2));
    onPartial(answer);
    return Ok(answer);
  }

  @override
  Future<Result<List<ChatMessage>>> loadConversation() async => Ok(stored);

  @override
  Future<Result<void>> saveConversation(List<ChatMessage> messages) async {
    stored = List.of(messages);
    return const Ok(null);
  }

  @override
  Future<Result<void>> clearConversation() async {
    stored = [];
    return const Ok(null);
  }
}
