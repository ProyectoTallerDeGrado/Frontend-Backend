import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/needs/domain/entities/venture_need.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_needs_repository.dart';

Future<void> _openNeeds(WidgetTester tester, FakeNeedsRepository needs) async {
  await pumpApp(
    tester,
    TestWorld(
      auth: FakeAuthRepository(token: 'tok-1'),
      needs: needs,
    ),
    height: 1400,
  );
  await tester.tap(find.text('Perfil'));
  await settle(tester);
  final entry = find.text('Necesidades y dificultades');
  await tester.ensureVisible(entry);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(entry);
  await settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder);
  await settle(tester);
}

void main() {
  testWidgets('sin reportes lo dice y ofrece reportar', (tester) async {
    await _openNeeds(tester, FakeNeedsRepository());
    expect(find.text('Todavía no has reportado nada.'), findsOneWidget);
    expect(find.text('Reportar'), findsOneWidget);
  });

  testWidgets('lista lo reportado con su tipo, prioridad y estado', (
    tester,
  ) async {
    await _openNeeds(
      tester,
      FakeNeedsRepository(
        needs: [
          VentureNeed(
            id: 1,
            categoryId: 1,
            categoryName: 'Marketing',
            kind: NeedKind.difficulty,
            priority: NeedPriority.high,
            resolved: false,
            description: 'No llego a clientes',
            detectedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          const VentureNeed(
            id: 2,
            categoryId: 2,
            categoryName: 'Financiamiento',
            kind: NeedKind.need,
            priority: NeedPriority.low,
            resolved: true,
          ),
        ],
      ),
    );
    expect(find.text('Dificultad'), findsOneWidget);
    expect(find.text('No llego a clientes'), findsOneWidget);
    expect(find.text('Abierta'), findsOneWidget);
    expect(find.text('Resuelta'), findsOneWidget);
    expect(find.textContaining('Prioridad alta'), findsOneWidget);
  });

  testWidgets('reporta una dificultad: rubro, prioridad y descripción', (
    tester,
  ) async {
    final needs = FakeNeedsRepository();
    await _openNeeds(tester, needs);

    await _tap(tester, find.text('Reportar'));
    await _tap(tester, find.text('Dificultad'));
    await _tap(tester, find.text('Alta'));
    await _tap(tester, find.byType(DropdownButtonFormField<int>));
    await _tap(tester, find.text('Marketing').last);
    await tester.enterText(find.byType(TextField), 'No llego a clientes');
    await tester.pump();
    await _tap(tester, find.text('Enviar reporte'));

    expect(needs.reportCalls, 1);
    expect(needs.lastCategoryId, 1);
    expect(needs.lastKind, NeedKind.difficulty);
    expect(needs.lastPriority, NeedPriority.high);
    expect(needs.lastDescription, 'No llego a clientes');
    // vuelve a la lista con el aviso y lo nuevo
    expect(find.textContaining('Reporte enviado'), findsOneWidget);
    expect(find.text('No llego a clientes'), findsOneWidget);
  });

  testWidgets('sin rubro ni descripción marca los campos y no envía', (
    tester,
  ) async {
    final needs = FakeNeedsRepository();
    await _openNeeds(tester, needs);
    await _tap(tester, find.text('Reportar'));
    await _tap(tester, find.text('Enviar reporte'));
    expect(needs.reportCalls, 0);
    expect(find.text('Elige un rubro.'), findsOneWidget);
  });

  testWidgets('si ya hay una abierta igual, el servidor lo explica', (
    tester,
  ) async {
    final needs = FakeNeedsRepository(
      failure: const NeedAlreadyRegisteredFailure(),
    );
    await _openNeeds(tester, needs);
    await _tap(tester, find.text('Reportar'));
    await _tap(tester, find.byType(DropdownButtonFormField<int>));
    await _tap(tester, find.text('Marketing').last);
    await tester.enterText(find.byType(TextField), 'Otra vez');
    await tester.pump();
    await _tap(tester, find.text('Enviar reporte'));
    expect(find.textContaining('Ya reportaste esa necesidad'), findsOneWidget);
    // sigue en el formulario para corregir
    expect(find.text('Enviar reporte'), findsOneWidget);
  });

  testWidgets('sin rubros definidos explica por qué no se puede reportar', (
    tester,
  ) async {
    await _openNeeds(tester, FakeNeedsRepository(categories: []));
    await _tap(tester, find.text('Reportar'));
    expect(find.textContaining('todavía no definió rubros'), findsOneWidget);
  });
}
