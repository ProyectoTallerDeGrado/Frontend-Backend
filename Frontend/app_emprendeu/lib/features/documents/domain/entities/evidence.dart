/// Archivo subido al servidor; si [milestoneId] existe, es evidencia de ese hito.
class Evidence {
  const Evidence({
    required this.id,
    required this.name,
    this.milestoneId,
    this.type,
    this.uploadedBy,
    this.uploadedAt,
  });

  final int id;
  final String name;
  final int? milestoneId;
  final String? type;

  /// Usuario que lo subió: solo esa persona (o el personal) puede eliminarlo.
  final int? uploadedBy;
  final DateTime? uploadedAt;
}
