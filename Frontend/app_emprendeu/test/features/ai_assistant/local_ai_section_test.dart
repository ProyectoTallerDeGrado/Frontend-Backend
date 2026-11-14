import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/local_ai_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_local_ai_repository.dart';

Future<void> _openProfile(WidgetTester tester, FakeLocalAiRepository ai) async {
  // Alto de sobra: la tarjeta queda visible sin desplazar.
  await pumpApp(
    tester,
    TestWorld(
      auth: FakeAuthRepository(token: 'tok-1'),
      localAi: ai,
    ),
    height: 2400,
  );
  await tester.tap(find.text('Perfil'));
  await settle(tester);
}

Future<void> _startDownload(WidgetTester tester) async {
  await tester.tap(find.textContaining('Descargar IA'));
  await settle(tester);
  expect(find.text('¿Descargar la IA?'), findsOneWidget);
  await tester.tap(find.widgetWithText(FilledButton, 'Descargar'));
  await settle(tester);
}

void main() {
  testWidgets('Perfil ofrece descargar la IA y muestra el tamaño', (
    tester,
  ) async {
    await _openProfile(tester, FakeLocalAiRepository());
    expect(find.text('IA en tu celular'), findsOneWidget);
    expect(find.text('Descargar IA (2,6 GB)'), findsOneWidget);
  });

  testWidgets('descargar muestra el avance y termina instalada', (
    tester,
  ) async {
    final ai = FakeLocalAiRepository();
    await _openProfile(tester, ai);
    await _startDownload(tester);
    expect(ai.installCalls, 1);

    ai.report(42);
    await settle(tester);
    expect(find.textContaining('42 %'), findsOneWidget);
    expect(find.text('Cancelar descarga'), findsOneWidget);

    ai.finish();
    await settle(tester);
    expect(find.text('Instalada en tu celular'), findsOneWidget);
    expect(find.text('Eliminar del celular'), findsOneWidget);
  });

  testWidgets('cancelar vuelve al botón de descarga sin mostrar error', (
    tester,
  ) async {
    final ai = FakeLocalAiRepository();
    await _openProfile(tester, ai);
    await _startDownload(tester);
    await tester.tap(find.text('Cancelar descarga'));
    await settle(tester);
    expect(find.textContaining('Descargar IA'), findsOneWidget);
    expect(find.text('Descarga cancelada.'), findsNothing);
  });

  testWidgets('un fallo de descarga se explica y permite reintentar', (
    tester,
  ) async {
    final ai = FakeLocalAiRepository();
    await _openProfile(tester, ai);
    await _startDownload(tester);
    ai.fail(const LocalAiFailure('No hay espacio suficiente en el celular.'));
    await settle(tester);
    expect(
      find.text('No hay espacio suficiente en el celular.'),
      findsOneWidget,
    );
    expect(find.textContaining('Descargar IA'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmación y libera la IA', (tester) async {
    final ai = FakeLocalAiRepository(current: LocalAiStatus.installed);
    await _openProfile(tester, ai);
    await tester.tap(find.text('Eliminar del celular'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await settle(tester);
    expect(ai.removeCalls, 1);
    expect(find.textContaining('Descargar IA'), findsOneWidget);
  });

  testWidgets('en un dispositivo no compatible no ofrece descargar', (
    tester,
  ) async {
    await _openProfile(
      tester,
      FakeLocalAiRepository(current: LocalAiStatus.unsupported),
    );
    expect(find.textContaining('Descargar IA'), findsNothing);
    expect(find.textContaining('todavía no puede usar la IA'), findsOneWidget);
  });
}
