/// Avance registrado por el emprendedor.
class ProgressLog {
  const ProgressLog({
    required this.text,
    required this.createdAt,
    this.id,
    this.clientRef,
    this.pendingSync = false,
  });

  /// Id del servidor; `null` mientras solo existe en el dispositivo.
  final int? id;

  /// Identificador generado en el dispositivo (evita duplicados al reenviar).
  final String? clientRef;
  final String text;
  final DateTime createdAt;
  final bool pendingSync;
}
