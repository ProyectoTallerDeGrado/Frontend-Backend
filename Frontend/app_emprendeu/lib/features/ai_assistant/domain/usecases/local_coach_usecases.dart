import '../../../../core/error/result.dart';
import '../entities/chat_message.dart';
import '../entities/knowledge_match.dart';
import '../entities/local_knowledge_status.dart';
import '../repositories/local_coach_repository.dart';
import '../repositories/local_knowledge_repository.dart';
import '../repositories/own_documents_repository.dart';
import 'assistant_usecases.dart';

/// Mismo texto que el coach del servidor cuando no hay información suficiente.
const localCoachFallback =
    'No encontré información suficiente en la base documental del CIE-U '
    'para responder con certeza.';

/// Temas en los que siempre se sugiere hablar con un mentor (igual que el servidor).
const _handoffKeywords = [
  'financ',
  'credito',
  'crédito',
  'inversi',
  'legal',
  'contrato',
  'demanda',
];

const localCoachSystemPrompt =
    'Eres el coach virtual del CIE-U (Centro de Innovación y Emprendimiento '
    'Universitario) y ayudas a emprendedores universitarios. Responde en '
    'español, claro y concreto, usando SOLO el contexto entregado. El contexto '
    'trae guías del CIE-U ([CIE-U: ...]) y archivos del propio emprendedor '
    '([Tu archivo: ...]): para recomendar mejoras compara sus archivos con las '
    'guías del CIE-U y di qué cambiaría y por qué. Si el contexto no alcanza, '
    'dilo. Para una pregunta simple usa como máximo 6 '
    'oraciones. Si te piden un plan, dalo en pasos numerados: qué hacer, cómo '
    'hacerlo y cuánto tiempo tomaría cada paso. No des asesoría legal ni '
    'financiera definitiva.';

/// Pregunta y respuesta del coach local, ya guardadas en el celular.
class LocalCoachAnswer {
  const LocalCoachAnswer({required this.question, required this.answer});

  final ChatMessage question;
  final ChatMessage answer;
}

/// RAG en el celular: busca en los documentos, y solo si hay fragmentos
/// relevantes le pide la respuesta al modelo (si no, no inventa).
class AskLocalCoachUseCase {
  AskLocalCoachUseCase(
    this._knowledge,
    this._coach, {
    this._own,
    this.topK = 4,
    this.ownTopK = 3,
    this.minScore = 0.45,
    this.historyTurns = 6,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LocalKnowledgeRepository _knowledge;
  final LocalCoachRepository _coach;
  final OwnDocumentsRepository? _own;

  /// Fragmentos del CIE-U y de los archivos propios que entran al contexto.
  final int topK;
  final int ownTopK;

  /// Umbral de similitud. Depende del modelo de embeddings: calibrado a ojo
  /// para EmbeddingGemma; se ajusta con `--dart-define=LOCAL_AI_MIN_SIMILARITY`.
  final double minScore;
  final int historyTurns;
  final DateTime Function() _clock;

  Future<Result<LocalCoachAnswer>> call(
    String message, {
    required List<ChatMessage> history,
    required void Function(String partial) onPartial,
  }) async {
    final text = message.trim();
    final invalid = coachMessageError(text);
    if (invalid != null) return Err(invalid);

    final found = await _knowledge.search(text, limit: topK);
    if (found case Err(:final failure)) return Err(failure);
    // Los archivos propios son opcionales: si fallan, se responde con el CIE-U.
    final mine = await _own?.search(text, limit: ownTopK);
    final matches = [
      ...?mine?.valueOrNull,
      ...found.valueOrNull!,
    ].where((m) => m.score >= minScore).toList();

    final String answerText;
    if (matches.isEmpty) {
      answerText = localCoachFallback;
    } else {
      final generated = await _coach.generate(
        system: localCoachSystemPrompt,
        prompt: buildLocalPrompt(text, matches, history, historyTurns),
        onPartial: onPartial,
      );
      if (generated case Err(:final failure)) return Err(failure);
      answerText = generated.valueOrNull!.trim();
    }

    final titles = [
      ...{for (final m in matches) _sourceLabel(m)},
    ];
    // Sin una guía del CIE-U que respalde la respuesta, se sugiere un mentor.
    final backedByCieu = matches.any((m) => !m.own);
    final lowered = text.toLowerCase();
    final id = _clock().microsecondsSinceEpoch;
    final question = ChatMessage(id: id, isUser: true, text: text);
    final answer = ChatMessage(
      id: id + 1,
      isUser: false,
      text: answerText.isEmpty ? localCoachFallback : answerText,
      sources: titles,
      suggestMentor:
          !backedByCieu || _handoffKeywords.any((k) => lowered.contains(k)),
    );
    // Si no se puede guardar, la respuesta igual se muestra.
    await _coach.saveConversation([...history, question, answer]);
    return Ok(LocalCoachAnswer(question: question, answer: answer));
  }
}

/// Prompt del modelo: contexto con el título de cada fragmento, los últimos
/// turnos de la conversación y la pregunta.
String buildLocalPrompt(
  String question,
  List<KnowledgeMatch> matches,
  List<ChatMessage> history,
  int historyTurns,
) {
  final buffer = StringBuffer('Contexto:\n');
  for (final m in matches) {
    buffer.writeln(
      '[${m.own ? 'Tu archivo' : 'CIE-U'}: ${m.title}] ${m.text}\n',
    );
  }
  final recent = history.length > historyTurns
      ? history.sublist(history.length - historyTurns)
      : history;
  if (recent.isNotEmpty) {
    buffer.writeln('Conversación previa:');
    for (final m in recent) {
      buffer.writeln('${m.isUser ? 'Emprendedor' : 'Coach'}: ${m.text}');
    }
    buffer.writeln();
  }
  buffer.write('Pregunta: $question');
  return buffer.toString();
}

class LoadLocalConversationUseCase {
  const LoadLocalConversationUseCase(this._coach);
  final LocalCoachRepository _coach;

  Future<Result<List<ChatMessage>>> call() => _coach.loadConversation();
}

class ClearLocalConversationUseCase {
  const ClearLocalConversationUseCase(this._coach);
  final LocalCoachRepository _coach;

  Future<Result<void>> call() => _coach.clearConversation();
}

class GetLocalKnowledgeStatusUseCase {
  const GetLocalKnowledgeStatusUseCase(this._knowledge);
  final LocalKnowledgeRepository _knowledge;

  Future<Result<LocalKnowledgeStatus>> call() => _knowledge.status();
}

/// Actualiza en el celular los documentos del CIE-U (requiere conexión).
class SyncLocalKnowledgeUseCase {
  const SyncLocalKnowledgeUseCase(this._knowledge);
  final LocalKnowledgeRepository _knowledge;

  Future<Result<LocalKnowledgeStatus>> call({
    void Function(int done, int total)? onProgress,
  }) => _knowledge.sync(onProgress: onProgress);
}

/// Cómo se muestra una fuente: los archivos propios se distinguen del CIE-U.
String _sourceLabel(KnowledgeMatch m) =>
    m.own ? 'Tu archivo: ${m.title}' : m.title;
