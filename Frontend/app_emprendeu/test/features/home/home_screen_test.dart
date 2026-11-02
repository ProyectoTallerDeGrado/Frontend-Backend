import '../auth/fake_auth_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await settle(tester, frames: 2);
  await tester.tap(finder);
  await settle(tester);
}

TestWorld _loggedIn({
  FakeVenturesRepository? ventures,
  FakeMentoringRepository? mentoring,
}) => TestWorld(
  auth: FakeAuthRepositoryWithToken(),
  ventures: ventures,
  mentoring: mentoring,
);

void main() {
  testWidgets(
    'el Inicio muestra progreso, siguiente reto, compromisos y avances',
    (tester) async {
      await pumpApp(tester, _loggedIn(), height: 1700);

      expect(find.text('Hola, Camila'), findsOneWidget);
      expect(find.text('Sabores del Oriente'), findsOneWidget);
      expect(find.text('En línea'), findsOneWidget);
      expect(find.text('Nivel 2'), findsOneWidget);
      expect(find.text('Te faltan 105 XP para el nivel 3.'), findsOneWidget);
      expect(find.text('Etapa: Incubación'), findsOneWidget);
      expect(find.text('Construir un prototipo mínimo'), findsOneWidget);
      expect(find.text('+150 XP'), findsOneWidget);
      expect(
        find.text('Enviar guion de entrevista a la mentora'),
        findsOneWidget,
      );
      expect(find.text('2 por hacer'), findsOneWidget);
      expect(
        find.textContaining('Primera entrevista realizada'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'sin emprendimiento se pide registrarlo y luego se activa el Inicio',
    (tester) async {
      final ventures = FakeVenturesRepository();
      await pumpApp(tester, _loggedIn(ventures: ventures), height: 1700);

      expect(find.text('Registra tu emprendimiento'), findsOneWidget);
      expect(find.text('Tareas y compromisos pendientes'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Mi Café');
      await _tapText(tester, 'Registrar emprendimiento');

      expect(ventures.createCalls, 1);
      expect(find.text('Mi Café'), findsOneWidget);
      expect(find.text('Tareas y compromisos pendientes'), findsOneWidget);
    },
  );

  testWidgets('marcar un compromiso lo tacha y baja el contador', (
    tester,
  ) async {
    final mentoring = FakeMentoringRepository();
    await pumpApp(tester, _loggedIn(mentoring: mentoring), height: 1700);

    await tester.tap(
      find.bySemanticsLabel(RegExp('Marcar como cumplido: Actualizar costos')),
    );
    await settle(tester);

    expect(find.text('1 por hacer'), findsOneWidget);
    expect(mentoring.commitments.last.done, isTrue);
  });

  testWidgets(
    'CU22: lo cumplido sale de la lista de pendientes y queda plegado aparte',
    (tester) async {
      final mentoring = FakeMentoringRepository();
      await pumpApp(tester, _loggedIn(mentoring: mentoring), height: 1700);
      expect(find.text('Cumplidos (0)'), findsNothing);

      await tester.tap(
        find.bySemanticsLabel(
          RegExp('Marcar como cumplido: Actualizar costos'),
        ),
      );
      await settle(tester);

      // ya no está entre los pendientes; aparece un acceso a los cumplidos
      expect(find.text('Actualizar costos del prototipo'), findsNothing);
      expect(
        find.text('Enviar guion de entrevista a la mentora'),
        findsOneWidget,
      );
      expect(find.text('Cumplidos (1)'), findsOneWidget);

      await tester.tap(find.text('Cumplidos (1)'));
      await settle(tester);
      expect(find.text('Actualizar costos del prototipo'), findsOneWidget);

      // devolverlo a pendiente lo regresa a la lista
      await tester.tap(
        find.bySemanticsLabel(
          RegExp('Marcar como pendiente: Actualizar costos'),
        ),
      );
      await settle(tester);
      expect(find.text('2 por hacer'), findsOneWidget);
      expect(find.text('Cumplidos (1)'), findsNothing);
    },
  );

  testWidgets(
    'CU22: sin tareas pendientes se felicita; sin compromisos se explica',
    (tester) async {
      final mentoring = FakeMentoringRepository(commitments: []);
      await pumpApp(tester, _loggedIn(mentoring: mentoring), height: 1700);
      expect(
        find.text(
          'Aún no tienes compromisos. Tu mentor los asignará en cada sesión.',
        ),
        findsOneWidget,
      );
      expect(find.text('0 por hacer'), findsOneWidget);
    },
  );

  testWidgets(
    'registrar un avance sin conexión lo deja pendiente y luego se sincroniza',
    (tester) async {
      final world = _loggedIn();
      await pumpApp(tester, world, height: 1700);

      // Se pierde la red.
      world.mentoring.offline = true;
      world.connectivity.set(false);
      await settle(tester);
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(
        find.textContaining('Sin conexión. Tus registros se guardan'),
        findsOneWidget,
      );

      await _tapText(tester, 'Registrar avance');
      expect(
        find.textContaining('Sin conexión: se guardará en tu dispositivo'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextField).last,
        'Probé el prototipo con 2 clientes',
      );
      await _tapText(tester, 'Guardar');

      expect(find.text('Probé el prototipo con 2 clientes'), findsOneWidget);
      expect(find.text('Pendiente de sincronizar'), findsOneWidget);
      expect(find.textContaining('Pendientes: 1.'), findsOneWidget);

      // Vuelve la red: se envía solo.
      world.mentoring.offline = false;
      world.connectivity.set(true);
      await settle(tester, frames: 10);

      expect(world.mentoring.syncCalls, 1);
      expect(find.text('Todo sincronizado.'), findsOneWidget);
      expect(find.text('Pendiente de sincronizar'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Todo sincronizado.'), findsNothing);
    },
  );

  testWidgets('guardar un avance vacío muestra el error y no lo envía', (
    tester,
  ) async {
    final world = _loggedIn();
    await pumpApp(tester, world, height: 1700);

    await _tapText(tester, 'Registrar avance');
    await _tapText(tester, 'Guardar');

    expect(find.text('Describe tu avance antes de guardar.'), findsOneWidget);
    expect(world.mentoring.logs.length, 1);
  });

  testWidgets('el botón del siguiente reto lleva al camino', (tester) async {
    await pumpApp(tester, _loggedIn(), height: 1700);
    await _tapText(tester, 'Ver en mi camino');
    expect(find.text('Mi camino'), findsOneWidget);
  });
}
