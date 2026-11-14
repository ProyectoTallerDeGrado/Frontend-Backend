import 'dart:io' show Platform;

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

import '../../domain/entities/local_ai_progress.dart';
import 'text_embedder.dart';

/// Envoltorio de `flutter_edge_ai` (LiteRT-LM): el único archivo que conoce el
/// paquete. Descarga dos modelos: uno de embeddings (buscar en documentos) y
/// uno de chat (redactar). Lanza las excepciones del paquete; el repositorio
/// las convierte en `Failure`.
class LocalAiEngineDataSource implements TextEmbedder {
  LocalAiEngineDataSource({
    required this.chatModelUrl,
    required this.chatModelBytes,
    required this.embedderUrl,
    required this.embedderBytes,
  });

  final String chatModelUrl;
  final int chatModelBytes;
  final String embedderUrl;
  final int embedderBytes;

  Future<void>? _ready;
  CancelToken? _cancel;

  /// Por ahora solo Android: en iOS LiteRT-LM exige un `Podfile` con enlace
  /// estático que el proyecto (Swift Package Manager) todavía no tiene.
  bool get isSupported => Platform.isAndroid;

  String get _chatFile => Uri.parse(chatModelUrl).pathSegments.last;
  String get _embedderFile => Uri.parse(embedderUrl).pathSegments.last;

  /// Registra el motor una sola vez; si falla, el siguiente intento lo repite.
  Future<void> _ensureReady() => _ready ??=
      FlutterEdgeAi.initialize(
        inferenceEngines: const [LiteRtLmEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      ).catchError((Object error) {
        _ready = null;
        throw error;
      });

  Future<bool> _chatInstalled() => FlutterEdgeAi.isModelInstalled(_chatFile);
  Future<bool> _embedderInstalled() =>
      FlutterEdgeAi.isModelInstalled(_embedderFile);

  Future<bool> isInstalled() async {
    await _ensureReady();
    return await _embedderInstalled() && await _chatInstalled();
  }

  /// Descarga lo que falte: primero el modelo de embeddings (pequeño) y luego el
  /// de chat. El avance se informa como porcentaje del total, ponderado por tamaño.
  Future<void> install(void Function(LocalAiProgress) onProgress) async {
    await _ensureReady();
    final token = _cancel = CancelToken();
    final total = embedderBytes + chatModelBytes;
    final embedderShare = embedderBytes / total;
    try {
      if (!await _embedderInstalled()) {
        await FlutterEdgeAi.installEmbedder()
            .modelFromNetwork(embedderUrl)
            .withModelProgress(
              (p) => onProgress(
                LocalAiProgress(
                  step: LocalAiStep.embedder,
                  percent: (p * embedderShare).round(),
                ),
              ),
            )
            .withCancelToken(token)
            .install();
      }
      if (!await _chatInstalled()) {
        await FlutterEdgeAi.installModel(
              modelType: ModelType.gemma4,
              fileType: ModelFileType.litertlm,
            )
            .fromNetwork(chatModelUrl)
            .withProgress(
              (p) => onProgress(
                LocalAiProgress(
                  step: LocalAiStep.chatModel,
                  percent: (embedderShare * 100 + p * (1 - embedderShare))
                      .round(),
                ),
              ),
            )
            .withCancelToken(token)
            .install();
      }
    } finally {
      if (identical(_cancel, token)) _cancel = null;
    }
  }

  void cancel() => _cancel?.cancel('Cancelado por la persona');

  /// Identidad del modelo de embeddings: si cambia, los vectores guardados ya
  /// no sirven y hay que recalcularlos.
  @override
  String get embedderId => _embedderFile;

  /// Contexto del modelo de chat (prompt + historial + respuesta), en tokens.
  static const _contextTokens = 4096;
  static const _maxAnswerTokens = 768;

  /// Vectores de fragmentos de documentos (lo que se busca).
  @override
  Future<List<List<double>>> embedDocuments(List<String> texts) async {
    await _ensureReady();
    final embedder = await FlutterEdgeAi.getActiveEmbedder();
    return embedder.embedAll([
      for (final t in texts) EmbeddingInput.text(t),
    ], taskType: TaskType.retrievalDocument);
  }

  /// Vector de una pregunta (con qué se busca).
  @override
  Future<List<double>> embedQuery(String text) async {
    await _ensureReady();
    final embedder = await FlutterEdgeAi.getActiveEmbedder();
    return embedder.embed(
      EmbeddingInput.text(text),
      taskType: TaskType.retrievalQuery,
    );
  }

  /// Genera la respuesta y la va entregando en [onPartial] (texto acumulado).
  /// Cada llamada abre un chat nuevo: el historial viaja dentro de [prompt].
  Future<String> generate({
    required String system,
    required String prompt,
    required void Function(String partial) onPartial,
  }) async {
    await _ensureReady();
    final model = await FlutterEdgeAi.getActiveModel(maxTokens: _contextTokens);
    final chat = await model.createChat(
      systemInstruction: system,
      maxOutputTokens: _maxAnswerTokens,
      modelType: ModelType.gemma4,
    );
    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
    final answer = StringBuffer();
    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        answer.write(response.token);
        onPartial(answer.toString());
      }
    }
    return answer.toString();
  }

  /// Borra los dos modelos. Lo que no estaba instalado se ignora.
  Future<void> remove() async {
    await _ensureReady();
    if (await _chatInstalled()) {
      await FlutterEdgeAi.uninstallModel(_chatFile);
    }
    if (await _embedderInstalled()) {
      await FlutterEdgeAi.uninstallEmbedder();
    }
    // Restos de descargas interrumpidas.
    await FlutterEdgeAi.cleanupStorage();
  }
}
