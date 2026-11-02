import '../../../../core/error/result.dart';
import '../entities/milestone.dart';
import '../entities/venture.dart';
import '../entities/venture_need.dart';

abstract interface class VenturesRepository {
  /// Primer emprendimiento del usuario, o `null` si aún no registró ninguno.
  Future<Result<Venture?>> getMine();

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

  /// Necesidades y dificultades registradas en el emprendimiento.
  Future<Result<List<VentureNeed>>> getNeeds(int ventureId);

  /// Registra una necesidad por nombre: si ya existe en el catálogo se reutiliza, si no se crea.
  Future<Result<VentureNeed>> addNeed(
    int ventureId, {
    required String name,
    required String priority,
    String? description,
  });

  Future<Result<VentureNeed>> resolveNeed(int needId);

  /// Nombres del catálogo, para sugerir mientras se escribe.
  Future<Result<List<String>>> getNeedCatalog();
}
