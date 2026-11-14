import 'dart:convert';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/local_coach_repository.dart';
import '../datasources/local_ai_engine_data_source.dart';

/// Genera con el modelo del celular y guarda la conversación local en el
/// dispositivo, bajo `user.` para que se borre al cerrar sesión.
class LocalCoachRepositoryImpl implements LocalCoachRepository {
  LocalCoachRepositoryImpl(this._engine, this._store);

  final LocalAiEngineDataSource _engine;
  final KeyValueStore _store;

  static const _key = 'user.coach.local_conversation';

  /// Mensajes guardados como máximo (los más recientes).
  static const _maxStored = 100;

  @override
  Future<Result<String>> generate({
    required String system,
    required String prompt,
    required void Function(String partial) onPartial,
  }) async {
    try {
      return Ok(
        await _engine.generate(
          system: system,
          prompt: prompt,
          onPartial: onPartial,
        ),
      );
    } on Object {
      return const Err(
        LocalAiFailure(
          'La IA del celular no pudo responder. Cierra otras apps e intenta '
          'de nuevo, o cambia al Coach en línea.',
        ),
      );
    }
  }

  @override
  Future<Result<List<ChatMessage>>> loadConversation() async {
    try {
      final raw = await _store.read(_key);
      if (raw == null) return const Ok([]);
      return Ok([
        for (final m in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          ChatMessage(
            id: m['id'] as int,
            isUser: m['user'] as bool,
            text: m['text'] as String,
            sources: (m['sources'] as List? ?? const []).cast<String>(),
            suggestMentor: m['mentor'] as bool? ?? false,
          ),
      ]);
    } on Object {
      return const Ok([]); // dañado: se empieza de cero
    }
  }

  @override
  Future<Result<void>> saveConversation(List<ChatMessage> messages) async {
    final recent = messages.length > _maxStored
        ? messages.sublist(messages.length - _maxStored)
        : messages;
    try {
      await _store.write(
        _key,
        jsonEncode([
          for (final m in recent)
            {
              'id': m.id,
              'user': m.isUser,
              'text': m.text,
              'sources': m.sources,
              'mentor': m.suggestMentor,
            },
        ]),
      );
      return const Ok(null);
    } on Object {
      return const Err(LocalAiFailure('No se pudo guardar la conversación.'));
    }
  }

  @override
  Future<Result<void>> clearConversation() async {
    await _store.remove(_key);
    return const Ok(null);
  }
}
