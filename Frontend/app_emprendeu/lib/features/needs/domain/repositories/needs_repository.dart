import '../../../../core/error/result.dart';
import '../entities/venture_need.dart';

/// Reportar y consultar necesidades y dificultades del emprendimiento (requiere conexión).
abstract interface class NeedsRepository {
  /// Rubros que el CIE-U definió; el emprendedor elige uno al reportar.
  Future<Result<List<NeedCategory>>> getCategories();

  /// Lo reportado por el emprendimiento [ventureId], lo más reciente primero.
  Future<Result<List<VentureNeed>>> getNeeds(int ventureId);

  Future<Result<VentureNeed>> report({
    required int ventureId,
    required int categoryId,
    required NeedKind kind,
    required NeedPriority priority,
    required String description,
  });
}
