/// Estado de la IA local (modelo de chat + modelo de embeddings) en este celular.
enum LocalAiStatus {
  /// Falta descargar al menos uno de los dos modelos.
  notInstalled,

  /// Los dos modelos están en el celular y la IA puede usarse sin servidor.
  installed,

  /// Este dispositivo no puede ejecutarla (por ahora solo Android arm64).
  unsupported,
}
