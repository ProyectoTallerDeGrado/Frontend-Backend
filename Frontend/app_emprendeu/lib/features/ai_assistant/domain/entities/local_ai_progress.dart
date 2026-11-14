/// Parte de la IA local que se está descargando.
enum LocalAiStep {
  /// Modelo de embeddings (pequeño): permite buscar en los documentos.
  embedder,

  /// Modelo de chat (grande): redacta las respuestas.
  chatModel,
}

/// Avance de la descarga: [percent] es el total (0–100), ponderado por tamaño.
class LocalAiProgress {
  const LocalAiProgress({required this.step, required this.percent});

  final LocalAiStep step;
  final int percent;

  @override
  bool operator ==(Object other) =>
      other is LocalAiProgress &&
      other.step == step &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(step, percent);
}
