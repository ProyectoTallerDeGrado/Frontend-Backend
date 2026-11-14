import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/needs/domain/entities/venture_need.dart';
import 'package:app_emprendeu/features/needs/domain/usecases/needs_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_needs_repository.dart';

Future<Result<VentureNeed>> _report(
  ReportNeedUseCase useCase, {
  int? categoryId = 1,
  String description = 'No llego a clientes',
}) => useCase(
  ventureId: 4,
  categoryId: categoryId,
  kind: NeedKind.difficulty,
  priority: NeedPriority.high,
  description: description,
);

void main() {
  group('ReportNeedUseCase (CU24)', () {
    test('sin rubro no llama al servidor', () async {
      final repo = FakeNeedsRepository();
      final result = await _report(ReportNeedUseCase(repo), categoryId: null);
      final failure = result.failureOrNull;
      expect(failure, isA<FieldFailure>());
      expect((failure as FieldFailure).field, 'category');
      expect(repo.reportCalls, 0);
    });

    test('una descripción vacía o en blanco se rechaza', () async {
      final repo = FakeNeedsRepository();
      final result = await _report(ReportNeedUseCase(repo), description: '   ');
      expect((result.failureOrNull as FieldFailure).field, 'description');
      expect(repo.reportCalls, 0);
    });

    test('una descripción demasiado larga se rechaza', () async {
      final repo = FakeNeedsRepository();
      final result = await _report(
        ReportNeedUseCase(repo),
        description: 'a' * (maxNeedDescriptionLength + 1),
      );
      expect(result.failureOrNull, isA<FieldFailure>());
      expect(repo.reportCalls, 0);
    });

    test('registra con el texto sin espacios sobrantes', () async {
      final repo = FakeNeedsRepository();
      final result = await _report(
        ReportNeedUseCase(repo),
        description: '  No llego a clientes  ',
      );
      expect(result, isA<Ok<VentureNeed>>());
      expect(repo.lastDescription, 'No llego a clientes');
      expect(repo.lastKind, NeedKind.difficulty);
      expect(repo.lastPriority, NeedPriority.high);
      expect(repo.lastVentureId, 4);
    });

    test('un duplicado del servidor llega como fallo claro', () async {
      final repo = FakeNeedsRepository(
        failure: const NeedAlreadyRegisteredFailure(),
      );
      final result = await _report(ReportNeedUseCase(repo));
      expect(result.failureOrNull, isA<NeedAlreadyRegisteredFailure>());
    });
  });
}
