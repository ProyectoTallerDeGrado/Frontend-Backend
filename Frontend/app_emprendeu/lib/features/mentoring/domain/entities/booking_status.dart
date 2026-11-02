/// Si el emprendimiento ya puede agendar mentorías (depende de su etapa).
class BookingStatus {
  const BookingStatus({required this.enabled, this.reason, this.stage});

  final bool enabled;

  /// Qué falta para habilitarlo; solo cuando [enabled] es falso.
  final String? reason;
  final String? stage;
}
