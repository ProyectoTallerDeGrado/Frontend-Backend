import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/ventures/domain/entities/venture.dart';
import 'package:app_emprendeu/features/ventures/domain/entities/venture_need.dart';
import 'package:app_emprendeu/features/ventures/domain/usecases/needs_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';

const _venture = Venture(id: 1, name: 'Sabores del Oriente');

Future<void> _openNeeds(
  WidgetTester tester,
  FakeVenturesRepository ventures,
) async {
  await pumpApp(
    tester,
    TestWorld(
      auth: FakeAuthRepository(token: 'tok-1'),
      ventures: ventures,
    ),
  );
  await tester.tap(find.text('Perfil'));
  await settle(tester);
  await _tap(tester, find.text('Necesidades y dificultades'));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder);
  await settle(tester);
}

void main() {
  group('AddNeedUseCase (CU24)', () {
    test('exige un nombre y respeta el largo máximo', () async {
      final repo = FakeVenturesRepository(venture: _venture);
      final useCase = AddNeedUseCase(repo);
      final blank = await useCase(1, name: '   ');
      expect((blank.failureOrNull as FieldFailure).field, 'name');
      final long = await useCase(1, name: 'a' * 161);
      expect(long.failureOrNull, isA<FieldFailure>());
      expect(repo.addNeedCalls, 0);
    });

    test(
      'limpia el texto y usa prioridad media si viene una inválida',
      () async {
        final repo = FakeVenturesRepository(venture: _venture);
        final result = await AddNeedUseCase(repo)(
          1,
          name: '  Capital  ',
          priority: 'urgentisima',
          description: '   ',
        );
        expect(result.valueOrNull?.name, 'Capital');
        expect(repo.lastNeedPriority, 'media');
        expect(repo.lastNeedDescription, isNull);
      },
    );
  });

  testWidgets('sin necesidades se invita a registrar la primera', (
    tester,
  ) async {
    await _openNeeds(tester, FakeVenturesRepository(venture: _venture));
    expect(find.text('Todavía no registraste necesidades.'), findsOneWidget);
    expect(find.text('Registrar necesidad'), findsOneWidget);
  });

  testWidgets('registra una necesidad con prioridad y detalle', (tester) async {
    final ventures = FakeVenturesRepository(venture: _venture);
    await _openNeeds(tester, ventures);

    await _tap(tester, find.text('Registrar necesidad'));
    await tester.enterText(find.byType(TextField).at(0), 'Clientes nuevos');
    await tester.enterText(
      find.byType(TextField).at(1),
      'No sé cómo llegar a más gente',
    );
    await _tap(tester, find.text('Alta'));
    await _tap(tester, find.text('Guardar'));

    expect(ventures.addNeedCalls, 1);
    expect(ventures.lastNeedName, 'Clientes nuevos');
    expect(ventures.lastNeedPriority, 'alta');
    expect(ventures.lastNeedDescription, 'No sé cómo llegar a más gente');
    expect(find.text('Clientes nuevos'), findsOneWidget);
    expect(find.textContaining('Sin resolver'), findsOneWidget);
    expect(find.textContaining('Prioridad Alta'), findsOneWidget);
  });

  testWidgets('sugiere necesidades del catálogo mientras escribe', (
    tester,
  ) async {
    final ventures = FakeVenturesRepository(venture: _venture);
    await _openNeeds(tester, ventures);
    await _tap(tester, find.text('Registrar necesidad'));

    await tester.enterText(find.byType(TextField).at(0), 'capital');
    await tester.pump();
    expect(
      find.widgetWithText(ActionChip, 'Capital de trabajo'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ActionChip, 'Asesoría legal'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, 'Capital de trabajo'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(field.controller?.text, 'Capital de trabajo');
  });

  testWidgets('un nombre vacío se marca y una necesidad repetida se explica', (
    tester,
  ) async {
    final ventures = FakeVenturesRepository(venture: _venture);
    await _openNeeds(tester, ventures);
    await _tap(tester, find.text('Registrar necesidad'));

    await _tap(tester, find.text('Guardar'));
    expect(find.text('Escribe qué necesitas o qué te cuesta.'), findsOneWidget);
    expect(ventures.addNeedCalls, 0);

    ventures.addNeedFailure = const FieldFailure(
      'name',
      'Ya registraste esa necesidad y sigue sin resolver.',
    );
    await tester.enterText(find.byType(TextField).at(0), 'Capital de trabajo');
    await _tap(tester, find.text('Guardar'));
    expect(
      find.text('Ya registraste esa necesidad y sigue sin resolver.'),
      findsOneWidget,
    );
  });

  testWidgets('marca una necesidad como resuelta', (tester) async {
    final ventures = FakeVenturesRepository(
      venture: _venture,
      needs: [
        VentureNeed(
          id: 7,
          name: 'Registro de marca',
          resolved: false,
          priority: 'media',
          detectedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    );
    await _openNeeds(tester, ventures);
    expect(find.textContaining('Sin resolver'), findsOneWidget);

    await _tap(tester, find.text('Marcar como resuelta'));
    expect(ventures.needs.single.resolved, true);
    expect(find.textContaining('Resuelta'), findsOneWidget);
    expect(find.text('Marcar como resuelta'), findsNothing);
  });
}
