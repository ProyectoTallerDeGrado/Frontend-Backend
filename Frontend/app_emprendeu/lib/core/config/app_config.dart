/// Configuración de la app. Se fija al compilar con `--dart-define`:
///
///     flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
///
/// El valor por defecto apunta al backend de la máquina anfitriona desde el
/// emulador de Android (`10.0.2.2`). En el simulador de iOS usa `127.0.0.1`.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.emprendeu.me/api/v1',
  );

  /// Modelo de chat de la IA local (formato `.litertlm`). Gemma 4 E2B, Apache-2.0,
  /// descarga pública sin token (~2,6 GB). Se cambia con `--dart-define=LOCAL_AI_CHAT_URL=...`.
  static const localAiChatModelUrl = String.fromEnvironment(
    'LOCAL_AI_CHAT_URL',
    defaultValue:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/'
        'resolve/main/gemma-4-E2B-it.litertlm',
  );

  /// Tamaño aproximado del modelo de chat, para avisar antes de descargar.
  static const localAiChatModelBytes = int.fromEnvironment(
    'LOCAL_AI_CHAT_BYTES',
    defaultValue: 2588147712,
  );

  /// Modelo de embeddings de la IA local (búsqueda en los documentos).
  /// EmbeddingGemma 2 de texto, Apache-2.0, ~165 MB, fijado a una revisión.
  static const localAiEmbedderUrl = String.fromEnvironment(
    'LOCAL_AI_EMBEDDER_URL',
    defaultValue:
        'https://huggingface.co/litert-community/'
        'embeddinggemma-2-text-270m-litert-lm/resolve/'
        '9be6e8b90982095dc05c2bd162e4b954ee4dbac7/'
        'embeddinggemma-2-text-270m.litertlm',
  );

  /// Similitud mínima (coseno) para usar un fragmento en el coach del celular.
  /// Depende del modelo de embeddings: ajústala al cambiarlo.
  static final localAiMinSimilarity =
      double.tryParse(
        const String.fromEnvironment('LOCAL_AI_MIN_SIMILARITY'),
      ) ??
      0.45;

  static const localAiEmbedderBytes = int.fromEnvironment(
    'LOCAL_AI_EMBEDDER_BYTES',
    defaultValue: 164626432,
  );
}
