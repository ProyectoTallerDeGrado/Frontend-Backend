import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../ventures/index.dart';
import '../../domain/entities/venture_need.dart';
import '../../domain/repositories/needs_repository.dart';
import '../../domain/usecases/needs_usecases.dart';

/// Contrato del repositorio; la implementación se inyecta en `app/providers.dart`.
final needsRepositoryProvider = Provider<NeedsRepository>(
  (ref) =>
      throw UnimplementedError('needsRepositoryProvider sin implementación'),
);

final getNeedCategoriesUseCaseProvider = Provider(
  (ref) => GetNeedCategoriesUseCase(ref.watch(needsRepositoryProvider)),
);
final getNeedsUseCaseProvider = Provider(
  (ref) => GetNeedsUseCase(ref.watch(needsRepositoryProvider)),
);
final reportNeedUseCaseProvider = Provider(
  (ref) => ReportNeedUseCase(ref.watch(needsRepositoryProvider)),
);

/// Rubros que el CIE-U definió para clasificar lo que se reporta.
final needCategoriesProvider = FutureProvider.autoDispose<List<NeedCategory>>(
  (ref) async =>
      (await ref.watch(getNeedCategoriesUseCaseProvider)()).getOrThrow(),
);

/// Lo reportado por el emprendimiento activo, lo más reciente primero.
final myNeedsProvider = FutureProvider.autoDispose<List<VentureNeed>>((
  ref,
) async {
  final ventureId = await ref.watch(currentVentureIdProvider.future);
  if (ventureId == null) throw const NoVentureFailure();
  return (await ref.watch(getNeedsUseCaseProvider)(ventureId)).getOrThrow();
});

/// Registrar una necesidad o dificultad. Devuelve `null` si salió bien o el [Failure].
class NeedsController extends Notifier<void> {
  @override
  void build() {}

  Future<Failure?> report({
    required int? categoryId,
    required NeedKind kind,
    required NeedPriority priority,
    required String description,
  }) async {
    final ventureId = await ref.read(currentVentureIdProvider.future);
    if (ventureId == null) return const NoVentureFailure();
    final result = await ref.read(reportNeedUseCaseProvider)(
      ventureId: ventureId,
      categoryId: categoryId,
      kind: kind,
      priority: priority,
      description: description,
    );
    switch (result) {
      case Ok():
        ref.invalidate(myNeedsProvider);
        return null;
      case Err(:final failure):
        return failure;
    }
    return null;
  }
}

final needsControllerProvider = NotifierProvider<NeedsController, void>(
  NeedsController.new,
);
