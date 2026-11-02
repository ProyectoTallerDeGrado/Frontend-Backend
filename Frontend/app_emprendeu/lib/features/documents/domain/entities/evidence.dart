/// Archivo subido al servidor; si [milestoneId] existe, es evidencia de ese hito.
class Evidence {
  const Evidence({
    required this.id,
    required this.name,
    this.milestoneId,
    this.type,
  });

  final int id;
  final String name;
  final int? milestoneId;
  final String? type;
}
