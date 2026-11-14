import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/needs/domain/entities/venture_need.dart';
import 'package:app_emprendeu/features/needs/domain/repositories/needs_repository.dart';

const marketing = NeedCategory(id: 1, name: 'Marketing');
const financing = NeedCategory(id: 2, name: 'Financiamiento');

/// Necesidades en memoria. [failure] simula que `report` falla (p. ej. duplicado).
class FakeNeedsRepository implements NeedsRepository {
  FakeNeedsRepository({
    List<NeedCategory>? categories,
    List<VentureNeed>? needs,
    this.failure,
  }) : categories = categories ?? [marketing, financing],
       needs = needs ?? [];

  List<NeedCategory> categories;
  final List<VentureNeed> needs;
  Failure? failure;

  int reportCalls = 0;
  int? lastVentureId;
  int? lastCategoryId;
  NeedKind? lastKind;
  NeedPriority? lastPriority;
  String? lastDescription;

  @override
  Future<Result<List<NeedCategory>>> getCategories() async =>
      Result.ok(categories);

  @override
  Future<Result<List<VentureNeed>>> getNeeds(int ventureId) async =>
      Result.ok(needs);

  @override
  Future<Result<VentureNeed>> report({
    required int ventureId,
    required int categoryId,
    required NeedKind kind,
    required NeedPriority priority,
    required String description,
  }) async {
    reportCalls++;
    lastVentureId = ventureId;
    lastCategoryId = categoryId;
    lastKind = kind;
    lastPriority = priority;
    lastDescription = description;
    if (failure != null) return Result.err(failure!);
    final created = VentureNeed(
      id: 100 + reportCalls,
      categoryId: categoryId,
      categoryName: categories.firstWhere((c) => c.id == categoryId).name,
      kind: kind,
      priority: priority,
      resolved: false,
      description: description,
      detectedAt: DateTime.now(),
    );
    needs.insert(0, created);
    return Result.ok(created);
  }
}
