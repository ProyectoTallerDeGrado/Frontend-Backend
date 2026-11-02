/// Hito del emprendimiento (CU20).
class Milestone {
  const Milestone({
    required this.id,
    required this.title,
    this.description,
    required this.done,
    this.estimatedAt,
    this.doneAt,
  });

  final int id;
  final String title;
  final String? description;
  final bool done;
  final DateTime? estimatedAt;
  final DateTime? doneAt;
}
