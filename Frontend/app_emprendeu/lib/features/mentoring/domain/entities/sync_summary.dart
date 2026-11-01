class SyncSummary {
  const SyncSummary({required this.synced, this.errors = const []});

  /// Registros enviados y aceptados por el servidor.
  final int synced;

  /// Registros que el servidor rechazó (se descartan: reintentarlos no ayuda).
  final List<String> errors;
}
