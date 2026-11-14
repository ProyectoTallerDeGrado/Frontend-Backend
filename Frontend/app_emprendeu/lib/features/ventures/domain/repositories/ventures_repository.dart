import '../../../../core/error/result.dart';
import '../entities/milestone.dart';
import '../entities/venture.dart';

abstract interface class VenturesRepository {
  /// Emprendimientos del usuario (puede estar en varios); vacío si no tiene.
  Future<Result<List<Venture>>> getMine();

  Future<Result<Venture>> create(String name);

  /// Edita los datos propios; el estado lo cambia solo la coordinación.
  Future<Result<Venture>> update(
    int ventureId, {
    required String name,
    String? description,
    String? sector,
  });

  Future<Result<List<Milestone>>> getMilestones(int ventureId);

  Future<Result<Milestone>> createMilestone(
    int ventureId, {
    required String title,
    String? description,
  });

  Future<Result<Milestone>> completeMilestone(int milestoneId);
}
